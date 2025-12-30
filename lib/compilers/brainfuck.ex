defmodule Compilers.Brainfuck do
  @moduledoc """
  Brainfuck compiler which translates code from Brainfuck to C.
  Tries to do it with some optimizations.
  """

  @tokens [
    ">",
    "<",
    "+",
    "-",
    ".",
    ",",
    "[",
    "]"
  ]

  @prologue [
    "#include <string.h>",
    "#include <stdio.h>",
    "int main(void) {",
    "int i = 0;",
    "char arr[30000];",
    "memset(arr, 0, sizeof(arr));"
  ]

  @epilogue [
    "return 0;",
    "}"
  ]

  def compile_file!(bf_file, options \\ []) do
    c_code = File.read!(bf_file) |> compile()

    file_name = Path.basename(bf_file, ".bf")

    c_file = "#{file_name}.c"
    File.write!(c_file, c_code)

    executable = Keyword.get(options, :executable, file_name)
    c_compiler = Keyword.get(options, :c_compiler, "gcc")
    System.cmd(c_compiler, ["-O2", "-o", executable, c_file], into: IO.stream())
  end

  def compile(code) do
    compiled_program =
      code
      |> tokenize()
      |> gen_bytecode([])
      |> optimize([])
      |> gen_c_code([])

    (@prologue ++ compiled_program ++ @epilogue)
    |> Enum.join("\n")
  end

  defp tokenize(code) do
    code
    |> String.graphemes()
    |> Enum.filter(&Enum.member?(@tokens, &1))
  end

  defp gen_bytecode([], commands), do: Enum.reverse(commands)

  defp gen_bytecode(["." | rest], commands),
    do: gen_bytecode(rest, [{:out} | commands])

  defp gen_bytecode(["," | rest], commands),
    do: gen_bytecode(rest, [{:in} | commands])

  defp gen_bytecode(["[", "-", "]" | rest], commands),
    do: gen_bytecode(rest, [{:zero} | commands])

  defp gen_bytecode(["[", "+", "]" | rest], commands),
    do: gen_bytecode(rest, [{:zero} | commands])

  defp gen_bytecode(["[" | rest], commands),
    do: gen_bytecode(rest, [{:while} | commands])

  defp gen_bytecode(["]" | rest], commands),
    do: gen_bytecode(rest, [{:end} | commands])

  defp gen_bytecode(["+" | _rest] = tokens, commands),
    do: gen_bytecode_repeated(tokens, "+", :add, commands)

  defp gen_bytecode(["-" | _rest] = tokens, commands),
    do: gen_bytecode_repeated(tokens, "-", :sub, commands)

  defp gen_bytecode(["<" | _rest] = tokens, commands),
    do: gen_bytecode_repeated(tokens, "<", :shift_left, commands)

  defp gen_bytecode([">" | _rest] = tokens, commands),
    do: gen_bytecode_repeated(tokens, ">", :shift_right, commands)

  defp gen_bytecode_repeated(tokens, token, command_name, commands) do
    {repeated, rest} = tokens |> Enum.split_while(&(&1 == token))
    command = {command_name, Enum.count(repeated)}
    gen_bytecode(rest, [command | commands])
  end

  defp optimize([], optimized), do: Enum.reverse(optimized)

  defp optimize([{:add, n}, {:sub, m} | rest], optimized) when n > m,
    do: optimize(rest, [{:add, n - m} | optimized])

  defp optimize([{:add, n}, {:sub, m} | rest], optimized) when n < m,
    do: optimize(rest, [{:sub, m - n} | optimized])

  defp optimize([{:add, n}, {:sub, m} | rest], optimized) when n == m,
    do: optimize(rest, optimized)

  defp optimize([{:sub, n}, {:add, m} | rest], optimized) when n > m,
    do: optimize(rest, [{:sub, n - m} | optimized])

  defp optimize([{:sub, n}, {:add, m} | rest], optimized) when n < m,
    do: optimize(rest, [{:add, m - n} | optimized])

  defp optimize([{:sub, n}, {:add, m} | rest], optimized) when n == m,
    do: optimize(rest, optimized)

  defp optimize([command | rest], optimized), do: optimize(rest, [command | optimized])

  defp gen_c_code([], c_code), do: Enum.reverse(c_code)

  defp gen_c_code([{:out} | rest], c_code),
    do: gen_c_code(rest, ["putchar(arr[i]);" | c_code])

  defp gen_c_code([{:in} | rest], c_code),
    do: gen_c_code(rest, ["arr[i] = getchar();" | c_code])

  defp gen_c_code([{:zero} | rest], c_code),
    do: gen_c_code(rest, ["arr[i] = 0;" | c_code])

  defp gen_c_code([{:while} | rest], c_code),
    do: gen_c_code(rest, ["while(arr[i]) {" | c_code])

  defp gen_c_code([{:end} | rest], c_code),
    do: gen_c_code(rest, ["}" | c_code])

  defp gen_c_code([{:add, n} | rest], c_code),
    do: gen_c_code(rest, ["arr[i] += #{n};" | c_code])

  defp gen_c_code([{:sub, n} | rest], c_code),
    do: gen_c_code(rest, ["arr[i] -= #{n};" | c_code])

  defp gen_c_code([{:shift_left, n} | rest], c_code),
    do: gen_c_code(rest, ["i -= #{n};" | c_code])

  defp gen_c_code([{:shift_right, n} | rest], c_code),
    do: gen_c_code(rest, ["i += #{n};" | c_code])
end
