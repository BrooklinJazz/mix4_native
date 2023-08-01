defmodule LiveViewNative.Test do
  use ExUnit.CaseTemplate

  using do
    quote do
      use Connect4Web.ConnCase
      import unquote(__MODULE__)
      ExUnit.Case.register_attribute(__MODULE__, :platform)
      ExUnit.Case.register_attribute(__MODULE__, :platforms)
      setup :set_platform_from_context
    end
  end

  def set_platform_from_context(ctx) do
    if platform = ctx.registered[:platform] do
      {:ok,
       conn:
         Phoenix.LiveViewTest.put_connect_params(ctx.conn, %{
           "_platform" => Atom.to_string(platform)
         })}
    else
      :ok
    end
  end

  defmacro cross_platform_test(name, context, do: block) do
    quote do
      previous_tags = Module.get_attribute(__MODULE__, :tag)

      for platform <- Module.get_attribute(__MODULE__, :platforms) || [:web, :swiftui] do
        for tag <- previous_tags do
          @tag tag
        end

        @tag platform
        @platform platform
        test "::#{platform |> Atom.to_string() |> String.upcase()}:: #{unquote(name)}",
             unquote(context) do
          unquote(block)
        end
      end
    end
  end
end
