-- docroc v0.1.0 - Lua documentation generator
-- https://github.com/bjornbytes/docroc
-- License - MIT, see LICENSE for details.

local docroc = {}

function docroc.process(filename)
  local text = love.filesystem.read(filename)

  local comments = {}
  text:gsub('%s*%-%-%-(.-)\n([%w\n][^\n%-]*)', function(chunk, context)
    --local a,b = string.find(chunk, "---")
	--print(string.sub(chunk, b, b+1))
    chunk = chunk:gsub('^%s*%-*%s*', ''):gsub('\n%s*%-*%s*', ' ')
    chunk = chunk:gsub('^[^@]', '@description %1')
    context = context:match('[^\n]+')

    local tags = {}
    chunk:gsub('@(%w+)%s?([^@]*)', function(name, body)
      body = body:gsub('(%s+)$', '')
      local processor = docroc.processors[name]
      local tag = processor and processor(body) or {}
      tag.tag = name
      tag.text = body
      tags[name] = tags[name] or {}
      table.insert(tags[name], tag)
      table.insert(tags, tag)
    end)

    table.insert(comments, {
      tags = tags,
      context = context
    })
  end)

  return comments
end

docroc.processors = {
  arg = function(body)
    local name = body:match('^%s*(%w+)') or body:match('^%s*%b{}%s*(%w+)')
    local description = body:match('%-%s*(.*)$')
    local optional, default
    local type = body:match('^%s*(%b{})'):sub(2, -2):gsub('(%=)(.*)', function(_, value)
      optional = true
      default = value
      if #default == 0 then default = nil end
      return ''
    end)

    return {
      type = type,
      name = name,
      description = description,
      optional = optional,
      default = default
    }
  end,

  returns = function(body)
    local type
    body:gsub('^%s*(%b{})', function(match)
      type = match:sub(2, -2)
      return ''
    end)
    local description = body:match('^%s*(.*)')

    return {
      type = type,
      description = description
    }
  end
}

return docroc