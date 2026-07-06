-- {"id":123456,"ver":"1.0.0","libVer":"1.0.0","author":"YourName","repo":"","dep":["DivineDaoLib"]}

local baseURL = "https://www.divinedaolibrary.com"
local name = "Divine Dao Library"
local lang = "en"
local listings = {
    {
        name = "Latest Updates",
        url = baseURL .. "/"
    },
    {
        name = "Novels",
        url = baseURL .. "/novels/"
    }
}

--- @param url string
--- @return string
local function getURL(url)
    local response = GET(url)
    if response.code ~= 200 then
        error("HTTP error: " .. response.code)
    end
    return response.body
end

--- Search
--- @param data table
--- @return table
function search(data)
    local query = data[QUERY]
    local page = data[PAGE_INDEX] or 1
    local url = baseURL .. "/?s=" .. query .. "&post_type=story"
    local doc = Document(getURL(url))

    local results = {}
    for _, v in ipairs(doc:select("article.story")) do
        local link = v:selectFirst("a")
        if link then
            table.insert(results, {
                title = link:text(),
                url = link:attr("href"),
                -- image = ... (add if needed)
            })
        end
    end
    return results
end

--- Popular / Latest
--- @param data table
--- @return table
function popular(data)
    -- For homepage/latest updates
    local doc = Document(getURL(baseURL))
    local results = {}

    -- Adjust selector based on actual structure (latest chapters on home)
    for _, v in ipairs(doc:select("div.latest-update, article.story")) do
        local link = v:selectFirst("a")
        if link then
            table.insert(results, {
                title = link:text():gsub("^%s*(.-)%s*$", "%1"),
                url = link:attr("href")
            })
        end
    end
    return results
end

--- Novel details
--- @param url string
--- @return table
function novel(url)
    local doc = Document(getURL(url))
    local novel = {}

    novel.title = doc:selectFirst("h1.entry-title"):text() or "Unknown"
    novel.authors = { doc:selectFirst("a[rel='author']"):text() or "" }
    novel.description = doc:selectFirst(".story-content, .entry-content"):text() or ""

    -- Chapters list (Fictioneer often has .chapter-list or similar)
    local chapters = {}
    for _, chap in ipairs(doc:select("a.chapter-link, .chapter")) do
        table.insert(chapters, {
            title = chap:text(),
            url = chap:attr("href")
        })
    end
    novel.chapters = chapters

    return novel
end

--- Chapter content
--- @param url string
--- @return string
function chapterContent(url)
    local doc = Document(getURL(url))
    -- Main content area - adjust selector as needed
    local content = doc:selectFirst(".story-content, .entry-content, article")
    if content then
        -- Clean common unwanted elements
        content:select("nav, .chapter-nav, .comments, script, style"):remove()
        return content:text()
    end
    return "Failed to load chapter content."
end

return {
    baseURL = baseURL,
    name = name,
    lang = lang,
    listings = listings,
    search = search,
    popular = popular,
    novel = novel,
    chapterContent = chapterContent
}
