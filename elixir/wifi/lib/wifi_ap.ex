defmodule WifiAp do
  @moduledoc """
  Starts an AP for clients to connect to - they are issued an IP once connected.

  WIP - captive portal - to allow updating wifi credentials for STA mode
  """

  def start() do
    # if we have persisted ssid + psk connect as sta, do not run ap.
    nvs_config = WifiConfig.get()

    IO.inspect(nvs_config)

    net_config =
      if nvs_config[:ssid] !== "" and nvs_config[:psk] !== "" do
        create_sta_config(nvs_config)
      else
        create_ap_config()
      end

    case :network.start(net_config) do
      {:ok, _pid} ->
        IO.puts("Network started!")
        Process.sleep(:infinity)

      error ->
        error
    end
  end

  defp create_sta_config(nvs_config) do
    sta_config =
      [
        connected: fn ->
          IO.inspect("Connected to #{nvs_config[:ssid]}")
        end,
        got_up: fn {ip, _netmask, gateway} ->
          IO.inspect("Got #{inspect(ip)} from #{inspect(gateway)}")
        end,
        disconnected: fn ->
          IO.inspect("Disconnected from  #{nvs_config[:ssid]}")
        end
      ] ++
        nvs_config

    snpm_config = [
      host: "time-d-b.nist.gov",
      synchronized: fn {tv_sec, tv_usec} ->
        IO.inspect("Synchronized time with SNTP server. tv_sec=#{tv_sec} tv_usec=#{tv_usec}")
      end
    ]

    [
      sta: sta_config,
      snpm: snpm_config
    ]
  end

  defp create_ap_config(ssid \\ "Test AtomVM AP", psk \\ "atomvm123") do
    ap_config = [
      ssid: ssid,
      psk: psk,
      ap_started: fn ->
        IO.inspect("AP Started ")

        spawn(fn -> DNSSpoof.start() end)
        spawn(fn -> PortalServer.start() end)
      end,
      sta_connected: fn mac ->
        IO.inspect("STA connected with mac #{inspect(mac)}")
      end,
      sta_ip_assigned: fn ip ->
        IO.inspect("STA assigned address #{inspect(ip)}")
      end,
      sta_disconnected: fn mac ->
        IO.inspect("STA disconnected with mac #{inspect(mac)}")
      end
    ]

    [
      ap: ap_config
    ]
  end
end
