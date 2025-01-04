defmodule Metar.Decoders do
  @moduledoc false

  @doc """
  decode_day/1 extracts day of the month from the time token.

  ## Example

      iex> decode_day("250453Z")
      "25"

  """
  def decode_day(token) do
    token |> String.slice(0, 2)
  end

  @doc """
  decode_time/1 extracts time of the day from the time token.

  ## Example

      iex> decode_day("250453Z")
      "04:53"

  """
  def decode_time(token) do
    token
    |> String.slice(2, 4)
    |> String.split_at(2)
    |> Tuple.to_list()
    |> Enum.join(":")
  end

  @doc """
  decode_wind/1 extracts wind direction, mean speed, gust speed and wind speed measure units from wind token.

  ## Example

      iex> decode_wind("20011G20KT")
      %{
        wspd: "11",
        wgst: "20",
        wdir: "200",
        wunits: "KT"
      }

  """
  def decode_wind(token) do
    %{}
    |> Map.put(:wdir, decode_wind_direction(token))
    |> Map.merge(decode_wind_speed(token))
  end

  defp decode_wind_direction(token), do: String.slice(token, 0..2)

  defp decode_wind_speed(token) do
    token
    |> String.slice(3..-1//1)
    |> String.split("G")
    |> decode_wind_speed_parts()
  end

  defp decode_wind_speed_parts([mean_speed_part]) do
    {mean_speed, units} =
      cond do
        String.starts_with?(mean_speed_part, "ABV") -> String.split_at(mean_speed_part, 5)
        String.starts_with?(mean_speed_part, "P") -> String.split_at(mean_speed_part, 3)
        true -> String.split_at(mean_speed_part, 2)
      end

    %{wspd: mean_speed, wunits: units}
  end

  defp decode_wind_speed_parts([mean_speed, gust_speed_part]) do
    {gust_speed, units} = String.split_at(gust_speed_part, 2)
    %{wspd: mean_speed, wgst: gust_speed, wunits: units}
  end

  @doc """
  decode_wind_variations/1 extracts range of the wind direction

  ## Example

      iex> decode_wind_variations("180V220")
      %{vwdir_min: "180", vwdir_max: "220"}

  """
  def decode_wind_variations(token) do
    [min, max] =
      token
      |> String.split("V")

    %{vwdir_min: min, vwdir_max: max}
  end

  @doc """
  decode_visib/1 extracts visibilty value. Value can be provided in meters or SM (statute miles). If value is in SM it will be transformed to meters.

  ## Example

      iex> decode_visib("1 1/2SM")
      %{visib: 2400}

      iex> decode_visib("2400")
      %{visib: 2400}

  """
  def decode_visib(token) do
    visib =
      if String.contains?(token, "SM") do
        decode_visib_in_sm(token)
      else
        String.to_integer(token)
      end

    %{visib: visib}
  end

  defp decode_visib_in_sm(token) do
    token
    |> String.slice(0..-3//1)
    |> string_sm_value_to_float()
    |> sm_to_meters()
    |> round()
    |> apply_metar_visib_rules()
  end

  defp string_sm_value_to_float(string_sm_value) do
    string_sm_value
    |> String.split(" ")
    |> case do
      [value | []] ->
        (String.contains?(value, "/") && fraction_to_float(value)) ||
          String.to_integer(value) * 1.0

      [int, fraction] ->
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
      visib < 50 -> 0
      visib < 800 -> visib - Integer.mod(visib, 50)
      visib >= 800 and visib < 5000 -> visib - Integer.mod(visib, 100)
      visib >= 5000 and visib < 10_000 -> visib - Integer.mod(visib, 1000)
      true -> 9999
    end
  end

  @doc """
  decode_and_add_clouds/2 decodes single clouds layer token: coverage type and base,
  and adds values map to the array of layers (several layers can be provided in a single METAR)

  ## Example

      iex> decode_and_add_clouds("FEW020", [])
      [%{cover: "FEW", base: 2000}]

      iex> decode_and_add_clouds("BKN300", [%{cover: "FEW", base: 2000}])
      [%{cover: "BKN", base: 30000}, %{cover: "FEW", base: 2000}]

  """
  def decode_and_add_clouds(token, existing_clouds) do
    %{clouds: existing_clouds ++ decode_clouds(token)}
  end

  defp decode_clouds(token) do
    {cover, base} =
      token
      |> String.split_at(3)

    base = if String.equivalent?(base, ""), do: nil, else: String.to_integer(base) * 100
    [%{cover: cover, base: base}]
  end

  @doc """
  decode_temp_and_dev_point/1 extracts tempreature and dev point from a single token

  ## Example

      iex> decode_temp_and_dev_point("31/21")
      %{temp: 31, devp: 21}

  """
  def decode_temp_and_dev_point(token) do
    [temp, dev_point] =
      token
      |> String.trim("M")
      |> String.split("/")
      |> Enum.map(&String.to_integer/1)

    %{temp: temp, devp: dev_point}
  end

  @doc """
  decode_cavok/1 sets visibility and clouds values which are represented by CAVOK

  ## Example

      iex> decode_cavok("CAVOK")
      %{visib: 9999, clouds: [%{cover: "CAVOK", base: nil}]}

  """
  def decode_cavok(token) do
    %{visib: 9999, clouds: [%{cover: token, base: nil}]}
  end
end
