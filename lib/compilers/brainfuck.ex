defmodule Compilers.Brainfuck do
  @moduledoc """
  Brainfuck compiler which translates code from Brainfuck to C.
  """

  @code_map %{
    ">" => "i++;",
    "<" => "i--;",
    "+" => "arr[i]++;",
    "-" => "arr[i]--;",
    "." => "putchar(arr[i]);",
    "," => "arr[i] = getchar();",
    "[" => "while(arr[i]) {",
    "]" => "}"
  }

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

  def compile_file!(file, executable_name \\ "output") do
    File.read!(file) |> compile!(executable_name)
  end

  def compile!(code, executable_name \\ "output") do
    c_file = "#{executable_name}.c"
    File.write!(c_file, compile(code))

    System.cmd("gcc", ["-O2", "-o", executable_name, c_file], into: IO.stream())
  end

  def compile(code) do
    compiled_program =
      code
      |> String.graphemes()
      |> Enum.filter(&Map.has_key?(@code_map, &1))
      |> Enum.map(&Map.fetch!(@code_map, &1))

    (@prologue ++ compiled_program ++ @epilogue)
    |> Enum.join("\n")
  end
end
