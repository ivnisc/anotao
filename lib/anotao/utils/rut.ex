defmodule Anotao.Utils.Rut do
  @moduledoc """
  utilidades para validación de RUT chileno con dígito verificador
  """

  # definimos el tipo de dato rut
  @type t :: String.t()

  @doc """
  obtiene el dígito verificador correcto para un rut
  """
  @spec get_check_digit(t()) :: binary()
  def get_check_digit(rut) do
    rut
    |> format_input
    |> String.to_integer
    |> Integer.digits
    |> Enum.reverse
    |> Enum.zip(cycle([2, 3, 4, 5, 6, 7], String.length(format_input(rut))))
    |> Enum.map(fn {num, index} -> num * index end)
    |> Enum.sum
    |> rem(11)
    |> format_check_digit
  end

  @doc """
  valida si un rut con formato 'xxxxxxxx-x' es válido
  """
  @spec is_valid?(t()) :: boolean()
  def is_valid?(rut) do
    case String.split(rut, "-") do
      [digits, check_digit] -> 
        String.upcase(check_digit) == String.upcase(get_check_digit(digits))
      _ -> false
    end
  end

  @doc """
  formatea un rut limpio para mostrar con guión
  """
  @spec format_display(t()) :: t()
  def format_display(rut) do
    clean = format_input(rut)
    case String.length(clean) do
      len when len >= 8 ->
        {body, dv} = String.split_at(clean, len - 1)
        "#{body}-#{String.upcase(dv)}"
      _ -> rut
    end
  end

  # genera ciclo de multiplicadores para el cálculo
  defp cycle(list, n), do: Stream.cycle(list) |> Enum.take(n)
  
  # formatea el dígito verificador según las reglas
  defp format_check_digit(0), do: "0"
  defp format_check_digit(1), do: "K"
  defp format_check_digit(check_digit), do: Integer.to_string(11 - check_digit)
  
  # limpia el input eliminando caracteres no numéricos (excepto K)
  defp format_input(rut), do: String.replace(rut, ~r/[^0-9kK]/, "")
end