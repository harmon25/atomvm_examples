defmodule PortalServer do
  @moduledoc """

  """

  def start(port \\ 80) do
    config = [
      {[],
       %{
         handler: __MODULE__
       }}
      # cannot seem to get the file handler to work - it does not find the file from priv
      # think i am missing something here for elixir
      # {[],
      #  %{
      #    handler: :httpd_file_handler,
      #    handler_config: %{
      #      app: :wifi
      #    }
      #  }}
    ]

    IO.puts("Starting httpd on port #{port}")

    case :httpd.start(port, config) do
      {:ok, _pid} ->
        IO.puts("httpd started")

      err ->
        :io.format("An error occurred: ~p~n", [err])
    end
  end

  def init_handler(suffix, config) do
    {:ok, %{path_suffix: suffix, config: config}}
  end

  def handle_http_req(%{method: :get} = _req, _state) do
    resp = """
    <!DOCTYPE html>
    <html lang="en">
    <head>
    <meta charset="UTF-8" />
    <title>AtomVM Web Console</title>
    <meta name="viewport" content="width=device-width, initial-scale=1" />
    <style>
    :root { color-scheme: light dark; font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif; line-height: 1.5; }
    body { margin: 0; min-height: 100vh; display: flex; align-items: center; justify-content: center; padding: 24px; background-color: #f3f4f6; color: #111827; }
    .card { width: min(360px, 100%); padding: clamp(20px, 4vw, 28px); border-radius: 18px; border: 1px solid rgba(15, 23, 42, 0.12); background: rgba(255, 255, 255, 0.94); box-shadow: 0 18px 36px rgba(15, 23, 42, 0.12); backdrop-filter: blur(6px); }
    h1 { margin: 0 0 10px; font-size: clamp(20px, 3vw, 24px); font-weight: 650; text-align: center; }
    p { margin: 0 0 20px; font-size: clamp(14px, 2.5vw, 16px); text-align: center; color: #4b5563; }
    form { display: grid; gap: 14px; }
    label { display: block; font-size: 14px; font-weight: 600; margin-bottom: 4px; color: #1f2937; }
    input[type="text"], input[type="password"] { width: 100%; padding: 10px 12px; border-radius: 12px; border: 1px solid rgba(15, 23, 42, 0.16); background: rgba(249, 250, 251, 0.9); color: inherit; transition: border-color 0.2s ease, box-shadow 0.2s ease; font-size: 16px; }
    input[type="text"]:focus, input[type="password"]:focus { outline: none; border-color: #2563eb; box-shadow: 0 0 0 3px rgba(37, 99, 235, 0.18); }
    button { width: 100%; padding: 10px 16px; border-radius: 999px; border: none; background: linear-gradient(135deg, #2563eb, #1d4ed8); color: #f9fafb; font-weight: 600; font-size: 16px; cursor: pointer; transition: transform 0.2s ease, box-shadow 0.2s ease; }
    button:hover { transform: translateY(-1px); box-shadow: 0 12px 16px rgba(37, 99, 235, 0.25); }
    button:focus-visible { outline: none; box-shadow: 0 0 0 4px rgba(37, 99, 235, 0.3); }
    @media (max-width: 480px) {
      body { padding: 12px; }
      .card { border-radius: 16px; padding: 18px; box-shadow: 0 14px 28px rgba(15, 23, 42, 0.12); }
    }
    @media (min-width: 768px) {
      body { padding: 48px; }
      form { gap: 16px; }
    }
    @media (prefers-color-scheme: dark) {
      body { background-color: #0f172a; color: #e2e8f0; }
      .card { background: rgba(15, 23, 42, 0.85); border: 1px solid rgba(148, 163, 184, 0.2); box-shadow: 0 24px 48px rgba(2, 6, 23, 0.6); }
      p { color: #cbd5f5; }
      label { color: #e2e8f0; }
      input[type="text"], input[type="password"] { background: rgba(15, 23, 42, 0.7); border: 1px solid rgba(148, 163, 184, 0.35); color: #f8fafc; }
      input[type="text"]:focus, input[type="password"]:focus { border-color: #38bdf8; box-shadow: 0 0 0 4px rgba(56, 189, 248, 0.22); }
      button { background: linear-gradient(135deg, #38bdf8, #0ea5e9); color: #0b1120; }
      button:hover { box-shadow: 0 12px 22px rgba(56, 189, 248, 0.35); }
    }
    </style>
    </head>
    <body>
    <main class="card">
      <h1>AtomVM Wi-Fi Setup</h1>
      <p>Choose your network and enter its credentials to bring this device online.</p>
      <form method="POST" action="/save">
        <label for="ssid">Network SSID</label>
        <input id="ssid" name="ssid" type="text" inputmode="text" autocapitalize="none" autocomplete="off" required />
        <label for="psk">Passphrase</label>
        <input id="psk" name="psk" type="password" inputmode="text" autocapitalize="none" autocomplete="off" required />
        <button type="submit">Save and Connect</button>
      </form>
    </main>
    </body>
    </html>
    """

    {:close, %{"Content-Type" => "text/html"}, resp}
  end

  def handle_http_req(%{method: :post} = req, _state) do
    %{
      headers: _headers,
      body: body
    } = req

    # extract body (ssid + psk and store in nvs)
    params = parse_form_body(body)
    WifiConfig.put(params.ssid, params.psk)

    resp = """
    <!DOCTYPE html>
    <html lang="en">
    <head>
    <meta charset="UTF-8" />
    <title>AtomVM Web Console</title>
    <meta name="viewport" content="width=device-width, initial-scale=1" />
    <style>
    :root { color-scheme: light dark; font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif; line-height: 1.5; }
    body { margin: 0; min-height: 100vh; display: flex; align-items: center; justify-content: center; padding: 20px; background-color: #f3f4f6; color: #111827; }
    .card { width: min(360px, 100%); padding: clamp(20px, 4vw, 28px); border-radius: 18px; border: 1px solid rgba(15, 23, 42, 0.12); background: rgba(255, 255, 255, 0.94); box-shadow: 0 18px 36px rgba(15, 23, 42, 0.12); text-align: center; backdrop-filter: blur(6px); }
    h2 { margin: 0 0 12px; font-size: clamp(20px, 3vw, 24px); font-weight: 650; }
    p { margin: 0 0 10px; font-size: clamp(14px, 2.5vw, 16px); color: #4b5563; }
    @media (max-width: 480px) {
      body { padding: 12px; }
      .card { border-radius: 16px; padding: 18px; box-shadow: 0 14px 28px rgba(15, 23, 42, 0.12); }
    }
    @media (min-width: 768px) {
      body { padding: 40px; }
    }
    @media (prefers-color-scheme: dark) {
      body { background-color: #0f172a; color: #e2e8f0; }
      .card { background: rgba(15, 23, 42, 0.85); border: 1px solid rgba(148, 163, 184, 0.2); box-shadow: 0 24px 48px rgba(2, 6, 23, 0.6); }
      p { color: #cbd5f5; }
    }
    </style>
    </head>
    <body>
    <section class="card">
      <h2>Connecting to Wi-Fi...</h2>
      <p>Your credentials were received. Attempting to join the network now.</p>
      <p>The device may reboot or reconnect shortly. Feel free to close this tab.</p>
    </section>
    </body>
    </html>
    """

    # restart after responding to post req
    spawn(fn ->
      Process.sleep(5000)
      :esp.restart()
    end)

    {:close, %{"Content-Type" => "text/html"}, resp}
  end

  def handle_http_req(_req, _state) do
    {:error, :internal_server_error}
  end

  # decode application/x-www-form-urlencoded payloads into a map without URI helpers
  def parse_form_body(body) do
    body
    |> :binary.split("&")
    |> Enum.reduce(%{}, fn
      "ssid=" <> ssid, acc -> Map.put(acc, :ssid, ssid)
      "psk=" <> psk, acc -> Map.put(acc, :psk, psk)
      _, acc -> acc
    end)
  end
end
