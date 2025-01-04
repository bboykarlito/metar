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
    :temp,
    :devp,
    clouds: []
  ]

  alias Metar.Decoders

  @moduledoc """
  Main module of the Elixir library for parsing METAR (METeorological Aerodrome Report). Provides API for decoding raw METAR strings. METAR is decoded into Metar structure.
  """

  @doc """
  decode/1 function for decodeing raw metar strings. Returns Metar structure with raw metar and extracted values:

  * **raw**: raw METAR string
  * **station**: ICAO code of the airport, which reported the METAR
  * **day**: Observation day of the month
  * **time**: Observation time of the day
  * **wdir**: Prevailing wind direction
  * **vwdir_min**: Variable wind direction left value
  * **vwdir_max**: Variable wind direction right value
  * **wspd**: Wind mean speed. Can start with *ABV* or *P* for speed above 99 knots
  * **wgst**: Wind gust
  * **wunits**: Wind speed measure units: *MPS* or *KT*
  * **visib**: Prevailing visibility in meters
  * **temp**: tempreature
  * **devp**: dev point
  * **clouds**: Array of cloud layers. For each layer amount as abbreviation and height in ft are provided

  ## Examples

      iex> Metar.decode("KMCI 250453Z 20011G15MPS 180V220 1 1/2SM FEW020 BKN300 31/21 A2982 RMK AO2 SLP084 T03060211")
      %Metar{
        raw: "KMCI 250453Z 20011MPS 1 1/2SM FEW020 BKN300 31/21 A2982 RMK AO2 SLP084 T03060211",
        station: "KMCI",
        day: "25",
        time: "04:53",
        wdir: "200",
        vwdir_min: "180",
        vwdir_max: "220",
        wspd: "11",
        wgst: "15",
        wunits: "MPS",
        visib: 2400,
        temp: 31,
        devp: 21,
        clouds: [%{cover: "FEW", base: 2000}, %{cover: "BKN", base: 30000}]
      }

  """
  def decode(raw_metar) do
    tokens = split_into_tokens(raw_metar)

    metar = %Metar{
      raw: raw_metar,
      station: Enum.at(tokens, 0),
      day: Decoders.decode_day(Enum.at(tokens, 1)),
      time: Decoders.decode_time(Enum.at(tokens, 1))
    }

    Enum.reduce(tokens, metar, &decode_token/2)
  end

  @doc """
  split_into_tokens/1 splits raw METAR string into tokens that represent some value.

  ## Example

      iex> split_into_tokens("KMCI 250453Z 20011MPS 1 1/2SM FEW2000 BKN3000 31/21 A2982 RMK AO2 SLP084 T03060211")
      ["KMCI", "250453Z", "20011MPS", "1 1/2SM", "FEW2000", "BKN3000", "31/21", "A2982", "RMK", "AO2", "SLP084", "T03060211"]

  """
  def split_into_tokens(raw_metar) do
    Regex.split(~r{\s((?=\d\/\dSM)(?<!\s\d\s)|(?!\d\/\dSM))|=}, raw_metar)
  end

  @doc false
  defp decode_token(token, metar) do
    wind_regex = ~r/^(VRB|\d{3})(ABV|P)?\d{2}G?(\d{2})?(MPS|KT)/
    wind_variations_regex = ~r/^(\d{3})V(\d{3})/
    visibility_regex = ~r/((^(\d{1,2}\s)?(\d\/)?(\d{1,2}SM))|^\d{4}$)/
    clouds_regex = ~r/^(FEW|SCT|BKN|OVC|CLR|SKC|NSC|NCD)/
    temp_regex = ~r/^(M)?(\d+\/\d+)/

    data =
      cond do
        String.match?(token, wind_regex) ->
          Decoders.decode_wind(token)

        String.match?(token, wind_variations_regex) ->
          Decoders.decode_wind_variations(token)

        String.match?(token, visibility_regex) ->
          Decoders.decode_visib(token)

        String.match?(token, clouds_regex) ->
          Decoders.decode_and_add_clouds(token, metar.clouds)

        String.match?(token, temp_regex) ->
          Decoders.decode_temp_and_dev_point(token)

        token == "CAVOK" ->
          Decoders.decode_cavok(token)

        true ->
          %{}
      end

    Map.merge(metar, data)
  end
end
