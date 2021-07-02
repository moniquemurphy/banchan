defmodule BanchanWeb.LayoutView do
  use BanchanWeb, :view

  def render(_, assigns) do
    ~F"""
    <html lang="en">
      <head>
        <meta charset="utf-8"/>
        <meta name="viewport" content="width=device-width, initial-scale=1.0"/>
        {Phoenix.HTML.Tag.csrf_meta_tag()}
        {live_title_tag assigns[:page_title] || "Banchan"}
        <link phx-track-static rel="stylesheet" href={Routes.static_path(@conn, "/css/app.css")}>
        <script defer phx-track-static type="text/javascript" src={Routes.static_path(@conn, "/js/app.js")}></script>
      </head>
      <body>
        {@inner_content}
      </body>
    </html>
    """
  end
end