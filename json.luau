Skip to content
 
Search Gists
Search...
All gists
Back to GitHub
@tylerneylon
tylerneylon/json.lua
Last active last week • Report abuse
Code
Revisions
4
Stars
163
Forks
34
Clone this repository at &lt;script src=&quot;https://gist.github.com/tylerneylon/59f4bcf316be525b30ab.js&quot;&gt;&lt;/script&gt;
<script src="https://gist.github.com/tylerneylon/59f4bcf316be525b30ab.js"></script>
Pure Lua json library.
json.lua
--[[ json.lua
A compact pure-Lua JSON library.
The main functions are: json.stringify, json.parse.
## json.stringify:
This expects the following to be true of any tables being encoded:
 * They only have string or number keys. Number keys must be represented as
   strings in json; this is part of the json spec.
 * They are not recursive. Such a structure cannot be specified in json.
A Lua table is considered to be an array if and only if its set of keys is a
consecutive sequence of positive integers starting at 1. Arrays are encoded like
so: `[2, 3, false, "hi"]`. Any other type of Lua table is encoded as a json
object, encoded like so: `{"key1": 2, "key2": false}`.
Because the Lua nil value cannot be a key, and as a table value is considerd
equivalent to a missing key, there is no way to express the json "null" value in
a Lua table. The only way this will output "null" is if your entire input obj is
nil itself.
An empty Lua table, {}, could be considered either a json object or array -
it's an ambiguous edge case. We choose to treat this as an object as it is the
more general type.
To be clear, none of the above considerations is a limitation of this code.
Rather, it is what we get when we completely observe the json specification for
as arbitrary a Lua object as json is capable of expressing.
## json.parse:
This function parses json, with the exception that it does not pay attention to
\u-escaped unicode code points in strings.
It is difficult for Lua to return null as a value. In order to prevent the loss
of keys with a null value in a json string, this function uses the one-off
table value json.null (which is just an empty table) to indicate null values.
This way you can check if a value is null with the conditional
`val == json.null`.
If you have control over the data and are using Lua, I would recommend just
avoiding null values in your data to begin with.
--]]


local json = {}


-- Internal functions.

local function kind_of(obj)
  if type(obj) ~= 'table' then return type(obj) end
  local i = 1
  for _ in pairs(obj) do
    if obj[i] ~= nil then i = i + 1 else return 'table' end
  end
  if i == 1 then return 'table' else return 'array' end
end

local function escape_str(s)
  local in_char  = {'\\', '"', '/', '\b', '\f', '\n', '\r', '\t'}
  local out_char = {'\\', '"', '/',  'b',  'f',  'n',  'r',  't'}
  for i, c in ipairs(in_char) do
    s = s:gsub(c, '\\' .. out_char[i])
  end
  return s
end

-- Returns pos, did_find; there are two cases:
-- 1. Delimiter found: pos = pos after leading space + delim; did_find = true.
-- 2. Delimiter not found: pos = pos after leading space;     did_find = false.
-- This throws an error if err_if_missing is true and the delim is not found.
local function skip_delim(str, pos, delim, err_if_missing)
  pos = pos + #str:match('^%s*', pos)
  if str:sub(pos, pos) ~= delim then
    if err_if_missing then
      error('Expected ' .. delim .. ' near position ' .. pos)
    end
    return pos, false
  end
  return pos + 1, true
end

-- Expects the given pos to be the first character after the opening quote.
-- Returns val, pos; the returned pos is after the closing quote character.
local function parse_str_val(str, pos, val)
  val = val or ''
  local early_end_error = 'End of input found while parsing string.'
  if pos > #str then error(early_end_error) end
  local c = str:sub(pos, pos)
  if c == '"'  then return val, pos + 1 end
  if c ~= '\\' then return parse_str_val(str, pos + 1, val .. c) end
  -- We must have a \ character.
  local esc_map = {b = '\b', f = '\f', n = '\n', r = '\r', t = '\t'}
  local nextc = str:sub(pos + 1, pos + 1)
  if not nextc then error(early_end_error) end
  return parse_str_val(str, pos + 2, val .. (esc_map[nextc] or nextc))
end

-- Returns val, pos; the returned pos is after the number's final character.
local function parse_num_val(str, pos)
  local num_str = str:match('^-?%d+%.?%d*[eE]?[+-]?%d*', pos)
  local val = tonumber(num_str)
  if not val then error('Error parsing number at position ' .. pos .. '.') end
  return val, pos + #num_str
end


-- Public values and functions.

function json.stringify(obj, as_key)
  local s = {}  -- We'll build the string as an array of strings to be concatenated.
  local kind = kind_of(obj)  -- This is 'array' if it's an array or type(obj) otherwise.
  if kind == 'array' then
    if as_key then error('Can\'t encode array as key.') end
    s[#s + 1] = '['
    for i, val in ipairs(obj) do
      if i > 1 then s[#s + 1] = ', ' end
      s[#s + 1] = json.stringify(val)
    end
    s[#s + 1] = ']'
  elseif kind == 'table' then
    if as_key then error('Can\'t encode table as key.') end
    s[#s + 1] = '{'
    for k, v in pairs(obj) do
      if #s > 1 then s[#s + 1] = ', ' end
      s[#s + 1] = json.stringify(k, true)
      s[#s + 1] = ':'
      s[#s + 1] = json.stringify(v)
    end
    s[#s + 1] = '}'
  elseif kind == 'string' then
    return '"' .. escape_str(obj) .. '"'
  elseif kind == 'number' then
    if as_key then return '"' .. tostring(obj) .. '"' end
    return tostring(obj)
  elseif kind == 'boolean' then
    return tostring(obj)
  elseif kind == 'nil' then
    return 'null'
  else
    error('Unjsonifiable type: ' .. kind .. '.')
  end
  return table.concat(s)
end

json.null = {}  -- This is a one-off table to represent the null value.

function json.parse(str, pos, end_delim)
  pos = pos or 1
  if pos > #str then error('Reached unexpected end of input.') end
  local pos = pos + #str:match('^%s*', pos)  -- Skip whitespace.
  local first = str:sub(pos, pos)
  if first == '{' then  -- Parse an object.
    local obj, key, delim_found = {}, true, true
    pos = pos + 1
    while true do
      key, pos = json.parse(str, pos, '}')
      if key == nil then return obj, pos end
      if not delim_found then error('Comma missing between object items.') end
      pos = skip_delim(str, pos, ':', true)  -- true -> error if missing.
      obj[key], pos = json.parse(str, pos)
      pos, delim_found = skip_delim(str, pos, ',')
    end
  elseif first == '[' then  -- Parse an array.
    local arr, val, delim_found = {}, true, true
    pos = pos + 1
    while true do
      val, pos = json.parse(str, pos, ']')
      if val == nil then return arr, pos end
      if not delim_found then error('Comma missing between array items.') end
      arr[#arr + 1] = val
      pos, delim_found = skip_delim(str, pos, ',')
    end
  elseif first == '"' then  -- Parse a string.
    return parse_str_val(str, pos + 1)
  elseif first == '-' or first:match('%d') then  -- Parse a number.
    return parse_num_val(str, pos)
  elseif first == end_delim then  -- End of an object or array.
    return nil, pos + 1
  else  -- Parse true, false, or null.
    local literals = {['true'] = true, ['false'] = false, ['null'] = json.null}
    for lit_str, lit_val in pairs(literals) do
      local lit_end = pos + #lit_str - 1
      if str:sub(pos, lit_end) == lit_str then return lit_val, lit_end + 1 end
    end
    local pos_info_str = 'position ' .. pos .. ': ' .. str:sub(pos, pos + 10)
    error('Invalid json syntax starting at ' .. pos_info_str)
  end
end

return json
Load earlier comments...
@zaoaz
zaoaz commented on Nov 25, 2016
really helpful ,Thanks a lot

@livem
livem commented on Nov 29, 2016
Thank you very much. ^_^

@derkalle4
derkalle4 commented on Apr 8, 2017
Wow. Clean. Tiny. Great! Thanks very much!

@DavyKoravand
DavyKoravand commented on Jun 12, 2017
It works perfectly, thanks!

@sensors2cloud
sensors2cloud commented on Nov 19, 2017
Great work! 5 Stars quality. worked first time.

@hypetsch
hypetsch commented on Jan 29, 2018
Hi @tylerneylon,

thanks for this great peace of code. Regarding the \u-limitation.
Im no a Lua specialist - what do you think, would adding something like this be ok to remove this limitation:

local text = "Ren\\u00e9"

function unescape(text)
  for uchar in string.gmatch(text, "\\u([0-9a-f][0-9a-f][0-9a-f][0-9a-f])") do
    text = text:gsub("\\u"..uchar, utf8.char("0x"..uchar))
  end
  return text
end 

print(text)
print(unescape(text))
@lotawei
lotawei commented on Dec 5, 2018
I am green coder , how to use the file in lua ，there is anybody show an example?

@tobiasvl
tobiasvl commented on Apr 4, 2019
@lotawei Put it in a file called (for example) json.lua, and include it in your project with something like json = require "json"

@richies-dev
richies-dev commented on Mar 25, 2020
You are awesome!

@akemrir
akemrir commented on Apr 9, 2020
Nice one. Thanks.

@monica18p
monica18p commented on Apr 19, 2020
What are the expected three params of json.parse(str, pos, end_delim) function?

@tylerneylon
Author
tylerneylon commented on Apr 20, 2020
Hi @monica18p, the expected usage is to call json.parse(my_json_str); ignore the 2nd and 3rd parameters. They exist entirely to enable json.parse() to recursively call itself for substrings. If you're curious, you can see this happening on lines 160 and 164.

@TaizWeb
TaizWeb commented on Apr 22, 2020 • 
Hi, I found a bug.
data = '{"link":"href=\"https://example.com\""}'
json.parse(data) // lua5.3: json.lua:189: Invalid json syntax starting at position 16: https://exa
It works fine without the escape sequence right after the = sign. I checked the JSON spec and it is in fact valid JSON

@tylerneylon
Author
tylerneylon commented on Apr 22, 2020
Hi @TaizWeb — I don't think this is a bug. When you provide Lua with the exact string you gave, like this:

> data = '{"link":"href=\"https://example.com\""}'
Lua will do the work of stripping out the escape characters. In interactive Lua, you can see this by just printing out data:

> data
{"link":"href="https://example.com""}
If you want to include the escape characters in the string itself, you have to escape them. (The first escape is so that the Lua interpreter knows to keep the second ones.) This works:

> data = '{"link":"href=\\"https://example.com\\""}'
> data
{"link":"href=\"https://example.com\""}
> t = json.parse(data)
> for key, value in pairs(t) do print(key, value) end
link	href="https://example.com"
@TaizWeb
TaizWeb commented on Apr 22, 2020
@tylerneylon Ahh, that makes sense. Thanks for the help!

@TaizWeb
TaizWeb commented on Apr 22, 2020
Hello again, my issue with the solution provided last was that in my case, I was getting data externally, meaning I couldn't check and edit manually. I wrote a quick function to add these escape sequences so that when fed into the JSON converter it wouldn't bug out over not being able to tell where a string stopped/started. Here it is for anyone coming here later in a similar predicament: https://gist.github.com/TaizWeb/8489b72d474aeb8dbd432b10ae372cc0

My function is also public domain, and I require no credit if you decide to use it in your programs.

@bikeNerd2020
bikeNerd2020 commented on Dec 31, 2020 • 
UPDATE:
After doing a bit of research online and a bit of trial and error I believe I have a firm understanding of the notation needed to retrieve values within the table. Thanks again this is going to be a huge time saver.

local s = json.parse("json string here")
local geoArea = "geo_area=" .. s.data[1].bounding_box[1].lat .. "," .. s.data[1].bounding_box[1].lng .. "|" .. s.data[1].bounding_box[2].lat .. "," .. s.data[1].bounding_box[2].lng
local agency = "agencies=" .. s.data[1].agency_id
UPDATE END:

@tylerneylon thank you very much for the use of this code. I am able to get the parser mostly working. However, I am unsure how to retrieve values within an array. I am able to retrieve values outside of the data array such as rate_limit, expires_in and api_version after the array.

Here is the incoming JSON that I am parsing:
{
"rate_limit": 0,
"expires_in": 3,
"data": [
{
"long_name": "origin",
"language": "en",
"position": {
"lat": 43.0378023361,
"lng": -87.9043960571
},
"name": "o",
"short_name": "ori",
"phone": "555-555-5555",
"url": "https://five.com/",
"timezone": "US/Central",
"bounding_box": [
{
"lat": 43.0344320633,
"lng": -87.9165792465
},
{
"lat": 43.0486215153,
"lng": -87.895731926
}
],
"agency_id": "555"
}
],
"api_version": "1.2"

@RKProgram
RKProgram commented on May 10, 2021
10/10 this is awesome

@Asharas
Asharas commented on Aug 25, 2021
I just spent de last two days trying to parse a table into JSON, multiple other libraries didn't work but this one does.
A thousand thanks!
🎉 🙏

@MegaRook
MegaRook commented on Jan 30, 2022
You saved a few hours of my life! Good luck!

@vivision1
vivision1 commented on Apr 20, 2022
I've tried
require "json" test = { one="8" , two="2" } print( test["one"] ) a=json.stringify( test)  print(a)
and it returns error attempt to index a nil value (global 'json')

what's wrong?

@bikeNerd2020
bikeNerd2020 commented on Apr 20, 2022
Assign the function to a variable...checkout my complete post above.

local s = json.parse("json string here")
local geoArea = "geo_area=" .. s.data[1].bounding_box[1].lat .. "," .. s.data[1].bounding_box[1].lng .. "|" .. s.data[1].bounding_box[2].lat .. "," .. s.data[1].bounding_box[2].lng
local agency = "agencies=" .. s.data[1].agency_id

@tylerneylon
Author
tylerneylon commented on Apr 20, 2022
Hi @TaizWeb — Sorry, I missed your earlier comments. I'm not sure if you are reporting a bug? If yes, and I can understand it, I'll put in a fix. Just let me know.

@tylerneylon
Author
tylerneylon commented on Apr 20, 2022
@vivision1 : When you import a module in lua, you want to use a statement like this:

local somemodule = require "somemodule"
So, in your case, you want to start with:

local json = require "json"
The error you see is because your runtime of lua never had the variable json defined. Using the above line will define it for you. (This is different from something like Python where just import something will define the name something for you; in lua you must assign the return value of require() to a variable so you can use it.)

@vivision1
vivision1 commented on Apr 21, 2022
@tylerneylon I just remove the local local json = {} to json = {} on your code before I saw your message and it worked
just: require "json" on the caller

@tiagoteixeiraJob
tiagoteixeiraJob commented on May 10, 2022
Thanks @tylerneylon and @bikeNerd2020 to share this knowledge.
You saved a few hours of my work day!
Excellent!

@shuaich
shuaich commented on Mar 19 • 
Thanks a lot for creating this library.

One question on escape_str(). What is the rationale to escape '/'? '/' is not a valid escape character in Lua. After escaping, http://stderr -> http:\/\/stderr, which IMHO is a bit confusing.

Much appreciated if you could clarify this for me.

@tylerneylon
Author
tylerneylon commented on Mar 20
Hi @shuaich , it's a good question. It turns out that you could edit escape_str() so that it doesn't escape forward slashes, and everything will work fine.

Why is the current code the way it is? Because when I wrote it I was looking at the JSON spec, which gives a short list of characters that can be escaped: https://www.json.org/json-en.html (scroll down to the "string" section)

After you asked your question, I myself was wondering why anyone would need to escape forward slashes. It turns out that HTML disallows strings inside a <script> tag from containing the character sequence </, and you can avoid those sequences by escaping forward slashes. Hence JSON supports that, hence my code above supports it. But, again, if you leave the forward slashes un-escaped, it is still valid JSON and you might like that way better! :)

For reference, here's the answer I found on stackoverflow about JSON escaping forward slashes:
https://stackoverflow.com/a/1580682/3561

@shuaich
shuaich commented on Mar 20
Thanks Tyler for your responsive and detailed answer. That makes total sense. 👍

@blaisedias
blaisedias commented 2 weeks ago
@tylerneylon ,
massive thanks for sharing this.

@TheAuthenticName
Comment
 
Leave a comment
 
Footer
© 2024 GitHub, Inc.
Footer navigation
Terms
Privacy
Security
Status
Docs
Contact
Manage cookies
Do not share my personal information
Pure Lua json library.
