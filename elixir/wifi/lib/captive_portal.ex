defmodule PortalServer do
  @moduledoc """

  Getting the following errors when submitting the form from iphone:

  ```
  "STA assigned address {192, 168, 4, 2}"
  I (20112) wifi:<ba-add>idx:2 (ifx:1, fb:b3:90:93:5b:e4), tid:0, ssn:0, winSize:64
  Caught error: throw:bad_line:[{httpd,parse_line,2,""},{httpd,parse_http_request,1,""},{httpd,handl]
  error in httpd. StatusCode=400  Error=bad_line
  Caught error: throw:bad_heading:[{httpd,parse_heading,4,""},{httpd,handle_http_request,3,""},{http]
  error in httpd. StatusCode=400  Error=bad_heading
  Send failed due to error {error,ebadf}
  Send failed due to error {error,ebadf}
  Send failed due to error {error,ebadf}
  Send failed due to error {error,ebadf}
  Send failed due to error {error,ebadf}
  Send failed due to error {error,ebadf}
  Send failed due to error {error,ebadf}
  Send failed due to error {error,ebadf}
  Send failed due to error {error,ebadf}
  Send failed due to error {error,ebadf}
  Send failed due to error {error,ebadf}
  Send failed due to error {error,ebadf}
  Send failed due to error {error,ebadf}
  Send failed due to error {error,ebadf}
  Send failed due to error {error,ebadf}
  Send failed due to error {error,ebadf}
  Send failed due to error {error,ebadf}
  Caught error: throw:bad_heading:[{httpd,parse_heading,4,""},{httpd,handle_http_request,3,""},{http]
  error in httpd. StatusCode=400  Error=bad_heading
  Send failed due to error {error,ebadf}
  Send failed due to error {error,ebadf}
  Send failed due to error {error,ebadf}
  Send failed due to error {error,ebadf}
  Send failed due to error {error,ebadf}
  Send failed due to error {error,ebadf}
  Send failed due to error {error,ebadf}
  ```

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
    <html>
    <head>
    <meta charset="UTF-8" />
    <title>AtomVM Web Console</title>
    <meta name="viewport" content="width=device-width, initial-scale=1" />
    </head>
    <body>
    <form method="POST" action="/save">
      SSID: <input type="text" name="ssid" /><br />
      PSK: <input type="text" name="psk" /><br />
      <input type="submit" />
    </form>
    </body>
    </html>
    """

    {:close, %{"Content-Type" => "text/html"}, resp}
  end

  def handle_http_req(%{method: :post} = req, _state) do
    %{
      headers: headers,
      body: body
    } = req

    # extract body (ssid + psk and store in nvs)
    IO.inspect(headers)
    IO.inspect(body)

    resp = """
    <html>
    <body>
    <h2>Connecting to Wi-Fi...</h2>
    <p>SSID:ssid</p>...
    <p>Please wait. The device will reboot or connect shortly.</p>
    </body>
    </html>
    """

    {:close, %{"Content-Type" => "text/html"}, resp}
  end

  def handle_http_req(_req, _state) do
    {:error, :internal_server_error}
  end
end
