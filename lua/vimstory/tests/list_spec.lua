require('plenary')
local List = require('vimstory.list')

local eq = assert.are.same

describe('list', function()
  it('add', function()
    local list = List:new('foo', {
      nil,
      nil,
      { value = 'three' },
      { value = 'four' },
    })

    eq(list.items, {
      nil,
      nil,
      { value = 'three' },
      { value = 'four' },
    })
    eq(list:length(), 4)

    local one = { value = 'one' }
    list:add(one)
    eq(list.items, {
      { value = 'one' },
      nil,
      { value = 'three' },
      { value = 'four' },
    })
    eq(list:length(), 4)

    local two = { value = 'two' }
    list:add(two)
    eq(list.items, {
      { value = 'one' },
      { value = 'two' },
      { value = 'three' },
      { value = 'four' },
    })
    eq(list:length(), 4)

    list:add({ value = 'five' })
    eq(list.items, {
      { value = 'one' },
      { value = 'two' },
      { value = 'three' },
      { value = 'four' },
      { value = 'five' },
    })
    eq(list:length(), 5)
  end)
end)
