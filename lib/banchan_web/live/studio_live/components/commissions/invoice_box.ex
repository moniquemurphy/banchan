defmodule BanchanWeb.StudioLive.Components.Commissions.InvoiceBox do
  @moduledoc """
  This is what shows up on the commission timeline when an artist asks for payment.
  """
  use BanchanWeb, :live_component

  alias Banchan.Commissions
  alias Banchan.Commissions.Event
  alias Banchan.Utils

  alias Surface.Components.Form

  alias BanchanWeb.Components.Button
  alias BanchanWeb.Components.Form.{Submit, TextInput}

  prop current_user_member?, :boolean, required: true
  prop current_user, :struct, required: true
  prop commission, :struct, required: true
  prop event, :struct, required: true
  prop uri, :string, required: true

  # NOTE: We're not actually going to create an event directly. We're just
  # punning off this for the changeset validation.
  data changeset, :struct, default: %Event{} |> Event.amount_changeset(%{})

  defp replace_fragment(uri, event) do
    URI.to_string(%{URI.parse(uri) | fragment: "event-#{event.public_id}"})
  end

  @impl true
  def handle_event("change", %{"event" => %{"amount" => amount}}, socket) do
    changeset =
      %Event{}
      |> Event.amount_changeset(%{"amount" => Utils.moneyfy(amount)})
      |> Map.put(:action, :insert)

    {:noreply, socket |> assign(:changeset, changeset)}
  end

  @impl true
  def handle_event("submit", %{"event" => %{"amount" => amount}}, socket) do
    changeset =
      %Event{}
      |> Event.amount_changeset(%{"amount" => Utils.moneyfy(amount)})
      |> Map.put(:action, :insert)

    if changeset.valid? do
      url =
        Commissions.process_payment!(
          socket.assigns.current_user,
          socket.assigns.event,
          socket.assigns.commission,
          replace_fragment(socket.assigns.uri, socket.assigns.event),
          Utils.moneyfy(amount)
        )

      {:noreply, socket |> redirect(external: url)}
    else
      {:noreply, socket |> assign(:changeset, changeset)}
    end
  end

  @impl true
  def handle_event("continue_payment", _, socket) do
    uri = socket.assigns.event.invoice && socket.assigns.event.invoice.checkout_url

    if uri do
      {:noreply, socket |> redirect(external: uri)}
    else
      {:noreply, socket}
    end
  end

  @impl true
  def handle_event("force_expire", _, socket) do
    Commissions.expire_payment!(socket.assigns.event.invoice, socket.assigns.current_user_member?)
    {:noreply, socket}
  end

  def render(assigns) do
    ~F"""
    <div class="flex flex-col">
      <div class="place-self-center stats stats-vertical md:stats-horizontal bg-neutral">
        <div class="stat">
          <div class="stat-title">Invoice</div>
          <div class="stat-value">{Money.to_string(@event.invoice.amount)}</div>
          {#case @event.invoice.status}
            {#match :pending}
              {#if @current_user.id == @commission.client.id}
                <div class="stat-desc">Payment is requested.</div>
                <Form for={@changeset} class="stat-actions" change="change" submit="submit">
                  <TextInput name={:amount} show_label={false} opts={placeholder: "Tip"} />
                  <Submit changeset={@changeset} label="Pay" />
                  {#if @current_user_member?}
                    {!-- # TODO: This should be a Link so it's accessible. --}
                    <Button click="force_expire" label="Cancel Payment" />
                  {/if}
                </Form>
              {#else}
                <div class="stat-desc">Waiting for Payment</div>
                {#if @current_user_member?}
                  <div class="stat-actions">
                    {!-- # TODO: This should be a Link so it's accessible. --}
                    <Button click="force_expire" label="Cancel Payment" />
                  </div>
                {/if}
              {/if}
            {#match :submitted}
              <div class="stat-desc">Payment session in progress.</div>
              <div class="stat-actions">
                {#if @current_user.id == @commission.client.id}
                  {!-- # TODO: This should be a Link so it's accessible. --}
                  <Button click="continue_payment" label="Continue Payment" />
                {/if}
                {#if @current_user_member?}
                  {!-- # TODO: This should be a Link so it's accessible. --}
                  <Button click="force_expire" label="Cancel Payment" />
                {/if}
              </div>
            {#match :expired}
              <div class="stat-desc">Payment session expired.</div>
            {#match :succeeded}
              <div class="stat-desc">Payment succeeded.</div>
            {#match :paid_out}
              <div class="stat-desc">Funds have been paid out.</div>
            {#match nil}
              {!-- NOTE: This state happens for a very brief window of time
                between when the payment request event is created, and when the
                Invoice itself is created, where there _is_ no
                Invoice for the event. If it's anything but a quick flash,
                there's probably a bug. --}
              <div class="stat-desc">Please wait...</div>
          {/case}
        </div>
        {#if @event.invoice.status == :succeeded || @event.invoice.status == :paid_out}
          <div class="stat">
            <div class="stat-title">Tip</div>
            <div class="stat-value">{Money.to_string(@event.invoice.tip)}</div>
            <div class="stat-desc">Thank you!</div>
          </div>
        {/if}
      </div>
      {#if @event.invoice.status == :succeeded}
        <span class="italic p-4 text-xs">
          Note: Banchan.Art will hold all funds for this commission until a final draft is approved.
        </span>
      {/if}
    </div>
    """
  end
end