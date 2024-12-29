defmodule Metar do
  defstruct [
    :raw,
    :station,
    :day,
    :time,
    :wdir,
    :vwdir_min,
    :vwdir_max,
    :wspd,
    :wgst,
    :wunits,
    :visib,
    # air tempreature
    :temp,
    # dev point
    :devp,
    clouds: []
  ]

  @moduledoc """
  Documentation for `Metar`.
  """

  @doc """
  Hello world.

  ## Examples

      iex> Metar.hello()
      :world

  """
  def decode(
        raw_metar \\ "KMCI 250453Z 20011MPS 1 1/2SM FEW2000 BKN3000 31/21 A2982 RMK AO2 SLP084 T03060211"
      ) do
    tokens = split_into_tokens(raw_metar)

    IO.puts("Tokens: #{Enum.join(tokens, ", ")}")

    metar = %Metar{
      raw: raw_metar,
      station: Enum.at(tokens, 0),
      day: extract_day(Enum.at(tokens, 1)),
      time: extract_time(Enum.at(tokens, 1))
    }

    Map.merge(metar, Enum.reduce(tokens, %{}, &decode_token/2))
  end

  defp split_into_tokens(raw_metar) do
    Regex.split(~r{\s((?=\d\/\dSM)(?<!\s\d\s)|(?!\d\/\dSM))|=}, raw_metar)
  end

  # In the token 250453Z, 25 - is the day of month
  defp extract_day(token) do
    token |> String.slice(0, 2)
  end

  # In the token 250453Z, 04:53 - is the time of the observation (UTC)
  defp extract_time(token) do
    token
    |> String.slice(2, 4)
    |> String.split_at(2)
    |> Tuple.to_list()
    |> Enum.join(":")
  end

  defp decode_token(token, metar) do
    wind_regex = ~r/^(VRB|\d{3})\d{2}G?(\d{2})?(MPS|KT)/
    wind_variations_regex = ~r/^(\d{3})V(\d{3})/
    visibility_regex = ~r/^(M)?(\d\s)?(\d\/)?(\dSM)/
    clouds_regex = ~r/^(FEW|SCT|BKN|OVC|CLR|SKC|NSC|NCD)/
    temp_regex = ~r/^(M)?(\d+\/\d+)/

    data =
      cond do
        String.match?(token, wind_regex) -> extract_wind(token)
        String.match?(token, wind_variations_regex) -> extract_wind_variations(token)
        String.match?(token, visibility_regex) -> extract_visib(token)
        String.match?(token, clouds_regex) -> extract_and_add_clouds(token, metar[:clouds])
        String.match?(token, temp_regex) -> extract_temp_and_dev_point(token)
        token == "CAVOK" -> extract_cavok(token)
        true -> %{}
      end

    Map.merge(metar, data)
  end

  # From 20011G20KT: dir 200 deg, speed 11 kt, gust 20 kt
  defp extract_wind(token) do
    %{}
    |> Map.put(:wdir, extract_wind_direction(token))
    |> Map.merge(extract_wind_speed(token))
  end

  defp extract_wind_direction(token) do
    case String.slice(token, 0..2) do
      "VRB" = dir -> dir
      dir -> String.to_integer(dir)
    end
  end

  defp extract_wind_speed(token) do
    token
    |> String.slice(3..-1//1)
    |> String.split("G")
    |> extract_wind_speed_parts()
  end

  defp extract_wind_speed_parts([mean_speed_part]) do
    {mean_speed, units} = String.split_at(mean_speed_part, 2)
    %{wspd: mean_speed, wunits: units}
  end

  defp extract_wind_speed_parts([mean_speed, gust_speed_part]) do
    {gust_speed, units} = String.split_at(gust_speed_part, 2)
    %{wspd: mean_speed, wgst: gust_speed, wunits: units}
  end

  defp extract_wind_variations(token) do
    [min, max] =
      token
      |> String.split("V")

    %{vwdir_min: min, vwdir_max: max}
  end

  # 1 1/2SM (Statute Miles)
  defp extract_visib(token) do
    visib =
      token
      |> String.slice(0..-3//1)
      |> string_sm_value_to_float()
      |> sm_to_meters()
      |> round()
      |> apply_metar_visib_rules()

    %{visib: visib}
  end

  defp string_sm_value_to_float(string_sm_value) do
    string_sm_value
    |> String.split(" ")
    |> case do
      [value | []] ->
        (String.contains?(value, "/") && fraction_to_float(value)) ||
          String.to_integer(value) * 1.0

      [int | [fraction]] ->
        String.to_integer(int) + fraction_to_float(fraction)
    end
  end

  defp fraction_to_float(fraction) do
    [numerator, denominator] =
      fraction
      |> String.split("/")
      |> Enum.map(&String.to_integer/1)

    numerator / denominator
  end

  defp sm_to_meters(sm) when is_float(sm) do
    sm * 1609.344
  end

  defp apply_metar_visib_rules(visib) do
    cond do
      visib < 800 -> visib - Integer.mod(visib, 50)
      visib >= 800 and visib < 5000 -> visib - Integer.mod(visib, 100)
      visib >= 5000 and visib < 10_000 -> visib - Integer.mod(visib, 1000)
      true -> 9999
    end
  end

  defp extract_and_add_clouds(token, nil) do
    %{clouds: extract_clouds(token)}
  end

  defp extract_and_add_clouds(token, existing_clouds) do
    %{clouds: existing_clouds ++ extract_clouds(token)}
  end

  defp extract_clouds(token) do
    {cover, base} =
      token
      |> String.split_at(3)

    base = if String.equivalent?(base, ""), do: nil, else: String.to_integer(base) * 100
    [%{cover: cover, base: base}]
  end

  defp extract_temp_and_dev_point(token) do
    [temp, dev_point] =
      token
      |> String.trim("M")
      |> String.split("/")
      |> Enum.map(&String.to_integer/1)

    %{temp: temp, devp: dev_point}
  end

  # CAVOK means visib is over 10 km
  defp extract_cavok(token) do
    %{visib: 9999, clouds: [%{cover: token, base: nil}]}
  end
end
