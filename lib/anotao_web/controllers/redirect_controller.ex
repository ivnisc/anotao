defmodule AnotaoWeb.RedirectController do
  use AnotaoWeb, :controller

  alias Anotao.Utils.Rut

  def index(conn, _params) do
    # renderiza la página principal con input de RUT
    render(conn, :index)
  end

  def redirect_to_notas(conn, %{"rut" => rut}) do
    case validate_rut(rut) do
      {:ok, clean_rut} ->
        # crear primera nota si el usuario no existe
        ensure_user_exists(clean_rut)
        redirect(conn, to: "/#{clean_rut}")

      {:error, reason} ->
        error_msg = get_error_message(reason)

        conn
        |> put_flash(:error, error_msg)
        |> render(:index, rut: rut)
    end
  end

  # validación completa de RUT chileno con dígito verificador
  defp validate_rut(rut) when is_binary(rut) do
    normalized_rut = normalize_rut(rut)

    cond do
      # rechazar RUTs que empiecen con 0s
      Regex.match?(~r/^0+/, normalized_rut) ->
        {:error, :starts_with_zeros}

      # validar formato básico
      !Regex.match?(~r/^[0-9]{7,8}-[0-9kK]$/i, normalized_rut) ->
        {:error, :invalid_format}

      # validar dígito verificador matemáticamente
      !Rut.is_valid?(normalized_rut) ->
        {:error, :invalid_check_digit}

      true ->
        formatted_rut = format_rut_for_url(normalized_rut)
        {:ok, formatted_rut}
    end
  end

  defp validate_rut(_), do: {:error, :invalid_input}

  # normaliza el RUT eliminando puntos y asegurando formato con guión
  defp normalize_rut(rut) do
    rut
    # eliminar todo excepto números y K
    |> String.replace(~r/[^0-9kK]/, "")
    # K en mayúscula
    |> String.upcase()
    |> case do
      clean when byte_size(clean) >= 8 and byte_size(clean) <= 9 ->
        # separar dígitos del dígito verificador
        {digits, dv} = String.split_at(clean, byte_size(clean) - 1)
        "#{digits}-#{dv}"

      _ ->
        # devolver original si no tiene formato válido
        rut
    end
  end

  # formatea el RUT para usar en URL (sin puntos, con guión)
  defp format_rut_for_url(rut) do
    case String.split(rut, "-") do
      [digits, dv] -> "#{digits}-#{String.downcase(dv)}"
      _ -> rut
    end
  end

  # mensajes de error específicos
  defp get_error_message(:starts_with_zeros), do: "RUT inválido. No puede empezar con ceros."
  defp get_error_message(:invalid_format), do: "Formato de RUT inválido."
  defp get_error_message(:invalid_check_digit), do: "Dígito verificador incorrecto."
  defp get_error_message(_), do: "RUT inválido."

  # crea notas iniciales si el usuario no existe
  defp ensure_user_exists(rut_usuario) do
    notas = Anotao.Notas.list_notas_by_usuario(rut_usuario)

    if length(notas) == 0 do
      # crear primera nota de bienvenida
      bienvenida_attrs = %{
        titulo: "Bienvenido a Anotao",
        contenido: "Puedes editarla o crear nuevas notas.\n\nAnota nomas jeje",
        rut_usuario: rut_usuario
      }

      # crear segunda nota de sample
      ejemplo_attrs = %{
        titulo: "Nota de ejemplo: Random Forest en DS",
        contenido: """
        ---

        ## Que es Random Forest?

        Random Forest es un *algoritmo de aprendizaje automático supervisado* que construye multiples árboles de decisión y los combina para mejorar la precisión y evitar sobreajuste.

        > Es como consultar a varios expertos en lugar de solo uno.

        ---

        ## Características principales

        - Basado en el principio de *bagging*.
        - Reduce el **overfitting** de un solo arbol.
        - Funciona bien en problemas de clasificacion y regresion.
        - Maneja grandes conjuntos de datos y alta dimensionalidad.
        - Estima la **importancia de las variables** automaticamente.
        - Cuantos mas arboles se usen (`n_estimators`), mas robusto será el modelo, pero aumentará el tiempo de entrenamiento.

        ---

        ## Código de ejemplo (clasificacion)

        ```python
        from sklearn.ensemble import RandomForestClassifier
        from sklearn.datasets import load_iris
        from sklearn.model_selection import train_test_split

        # datos
        X, y = load_iris(return_X_y=True)
        X_train, X_test, y_train, y_test = train_test_split(X, y, random_state=42)

        # modelo
        clf = RandomForestClassifier(n_estimators=100, random_state=42)
        clf.fit(X_train, y_train)

        # prediccion
        print(clf.predict(X_test))
        ```
        """,
        rut_usuario: rut_usuario
      }

      Anotao.Notas.create_nota(bienvenida_attrs)
      Anotao.Notas.create_nota(ejemplo_attrs)
    end
  end
end
