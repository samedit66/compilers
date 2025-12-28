defmodule Compilers.CLI do
  alias Compilers.Brainfuck, as: Brainfuck

  def main(args \\ []) do
    with {:ok, file} <- parse_args(args) do
      Brainfuck.compile_file!(file)
    else
      {:error, reason} -> IO.puts(:stderr, reason)
    end
  end

  defp parse_args([]), do: {:error, "Expected a file to compile"}

  defp parse_args(args) do
    {_options, [file | _rest], _unknown} =
      args
      |> OptionParser.parse(aliases: [o: :output], strict: [output: :string])

    {:ok, file}
  end
end
