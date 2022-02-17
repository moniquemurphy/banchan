defmodule BanchanWeb.StudioLive.Components.CommissionCard do
  @moduledoc """
  Card component for commissions
  """
  use BanchanWeb, :component

  alias Surface.Components.LiveRedirect

  alias Banchan.Offerings

  alias BanchanWeb.Components.Card
  alias BanchanWeb.Endpoint

  prop studio, :struct, required: true
  prop offering, :struct, required: true

  def render(assigns) do
    base_price = Offerings.offering_base_price(assigns.offering)
    available_slots = Offerings.offering_available_slots(assigns.offering)

    ~F"""
    <Card>
      <:header>
        <div class="text-lg font-bold">{@offering.name}</div>
      </:header>
      <:header_aside>
        {#if @offering.open && !is_nil(@offering.slots)}
          <div class="badge badge-outline badge-success">{available_slots}/{@offering.slots} Slots</div>
        {#elseif !@offering.open && !is_nil(@offering.slots)}
          <div class="badge badge-error badge-outline">0/{@offering.slots} Slots</div>
        {#elseif @offering.open}
          <div class="badge badge-success badge-outline">Open</div>
        {#else}
          <div class="badge badge-error badge-outline">Closed</div>
        {/if}
        {#if @offering.hidden}
          <div class="badge badge-error badge-outline">Hidden</div>
        {/if}
      </:header_aside>
      <:image>
        <img class="object-cover" src={Routes.static_path(Endpoint, "/images/hj-illustration.jpg")}>
      </:image>
      <div class="flex flex-col grow">
        <p class="mt-2 grow flex">{@offering.description}</p>
        <p class="text-success mt-2 grow-0">
          <span class="font-bold">Base Price:</span>
          {#if base_price}
            <span class="float-right">{base_price}</span>
          {#else}
            <span class="float-right">Inquire</span>
          {/if}
        </p>
      </div>
      <:footer>
        <div class="justify-end card-actions">
          {#if @offering.open}
            <LiveRedirect
              to={Routes.studio_commissions_new_path(Endpoint, :new, @studio.handle, @offering.type)}
              class="btn text-center btn-info"
            >Request</LiveRedirect>
          {#else}
            <LiveRedirect to="#" class="btn text-center btn-info">Notify Me</LiveRedirect>
          {/if}
        </div>
      </:footer>
    </Card>
    """
  end
end
