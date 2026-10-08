
read_file = fn file ->
  case File.read file do
    {:ok, contents} ->
      contents
    {:error, :enoent} ->
      IO.puts("The given file: #{file} does not exist in this context.")
      System.stop()
    {:error, reason} ->
      IO.puts("Something went wrong while trying to read #{file}: #{reason}")
      System.stop()
  end
end

write_out = fn
  data, file ->
    case File.write(file, data, [:append]) do
      :ok ->
        true
      {:error, reason} ->
        IO.puts("Failed to write to #{file}. Reason: #{reason}")
    end
end

file_to_read = case System.argv() do
  [file] ->
    [file]
  _ ->
    IO.puts("Please argue a file to transpile.")
    System.stop()
end

lines = file_to_read
|> read_file.()
|> String.split("\n")

contains_boilerplate = """
local function contains(array, item)
	for _, part in ipairs(array) do
		if part == item then return true end
	end
	return false
end

"""

blank_boilerplate = """
local function isBlank(str)
  if type(str) == "number" then
      error("You cannot check if a number is blank. You passed an integer to isBlank()")
  end

  if str == nil then return true end
  if str == false then return true end
  if str == "" then return true end

  local trimmed = str:match("^%s*(.-)%s*$")
  if trimmed == "" then return true end

  return false
end

-- end Hiramasa boilerplate

"""


new_lines = Enum.map(lines, fn line ->
  line
  |> then(&Regex.replace(~r/(\w+)\.(includes|has|contains)\?\(?(\w+)\)?/, &1, "contains(\\1, \\3)")) # Array.includes?("foo")
  |> then(&Regex.replace(~r/(foreach|for) (\w+) in (\w+) do/, &1, "for _, \\2 in ipairs(\\3) do")) # foreach song in album do
  |> then(&Regex.replace(~r/(\w+)\.blank\?/, &1, "isBlank(\\1)")) # String.blank?
  |> then(&Regex.replace(~r/(\w+) = io\.open!\(("[^"]+"), ("[^"]+")\)/, &1, """
  \\1 = io.open(\\2, \\3)

  if not \\1 then
	  print("Error: Could not open file " .. \\2 .. " Are you sure it exists in this context?")
    os.exit(1)
  end
  """)) # io.open!
  |> then(&Regex.replace(~r/\.nil\?/, &1, " == nil")) # .nil?
end) |> Enum.join("\n")

file = "hiramasa.lua"

output = cond do
  Enum.any?(lines, fn line -> String.contains?(line, ~w[includes? has? contains?]) end) and
  Enum.any?(lines, fn line -> String.contains?(line, ".blank?") end) ->
    contains_boilerplate <> blank_boilerplate <> new_lines

  Enum.any?(lines, fn line -> String.contains?(line, ~w[includes? has? contains?]) end) ->
    contains_boilerplate <> new_lines
  Enum.any?(lines, fn line -> String.contains?(line, ".blank?") end) ->
    blank_boilerplate <> new_lines
  true ->
    new_lines
end


write_out.(output, file)
