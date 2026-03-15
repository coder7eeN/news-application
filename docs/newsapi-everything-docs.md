# NewsAPI — `/v2/everything` Endpoint

> Search through millions of articles from over 150,000 news sources and blogs published in the last 5 years. Ideal for **news analysis**, **article discovery**, and building news-powered applications.

---

## Base URL

```
GET https://newsapi.org/v2/everything
```

---

## Authentication

Your API key must be included with every request. It can be passed in two ways:

| Method | Example |
|---|---|
| Query parameter | `?apiKey=YOUR_API_KEY` |
| HTTP Header | `X-Api-Key: YOUR_API_KEY` |

> ⚠️ **Never expose your API key in client-side code.** Store it as an environment variable.

---

## Example Request (from URL)

```
GET https://newsapi.org/v2/everything?q=tesla&from=2026-02-14&sortBy=publishedAt&apiKey=YOUR_API_KEY
```

This fetches all articles mentioning **Tesla**, published on or after **February 14, 2026**, sorted by **most recent first**.

---

## Query Parameters

### Required (at least one of `q`, `sources`, or `domains` must be provided)

| Parameter | Type | Description |
|---|---|---|
| `q` | `string` | Keywords or phrases to search for in article titles and bodies. Max 500 characters. URL-encode the value. |
| `sources` | `string` | Comma-separated list of source identifiers (max 20). Use the `/v2/sources` endpoint to find valid IDs. |
| `domains` | `string` | Comma-separated list of domains to restrict results to (e.g. `bbc.co.uk,techcrunch.com`). |

### Optional

| Parameter | Type | Default | Description |
|---|---|---|---|
| `qInTitle` | `string` | — | Same syntax as `q`, but restricts the search to **article titles only**. |
| `searchIn` | `string` | `title,description,content` | Comma-separated fields to search. Options: `title`, `description`, `content`. |
| `excludeDomains` | `string` | — | Comma-separated list of domains to **exclude** from results (e.g. `example.com`). |
| `from` | `string` | Oldest per plan | Oldest publish date allowed. ISO 8601 format: `YYYY-MM-DD` or `YYYY-MM-DDTHH:MM:SS`. |
| `to` | `string` | Newest per plan | Most recent publish date allowed. ISO 8601 format: `YYYY-MM-DD` or `YYYY-MM-DDTHH:MM:SS`. |
| `language` | `string` | All | 2-letter ISO-639-1 language code. Options: `ar` `de` `en` `es` `fr` `he` `it` `nl` `no` `pt` `ru` `se` `ud` `zh`. |
| `sortBy` | `string` | `publishedAt` | Sort order of results. Options: `relevancy`, `popularity`, `publishedAt`. |
| `pageSize` | `integer` | `20` | Number of results per page. Max: `100`. |
| `page` | `integer` | `1` | Page number for paginating through results. |
| `apiKey` | `string` | — | **Required.** Your API key (if not sent via header). |

---

### `q` Parameter — Advanced Search Syntax

The `q` parameter supports boolean operators for precise filtering:

| Syntax | Description | Example |
|---|---|---|
| Plain keyword | Match any article containing the word | `q=tesla` |
| `"quoted phrase"` | Exact phrase match | `q="electric vehicles"` |
| `+word` | Word **must** appear | `q=+tesla` |
| `-word` | Word **must not** appear | `q=tesla -musk` |
| `AND` | Both terms required | `q=tesla AND battery` |
| `OR` | Either term | `q=tesla OR rivian` |
| `NOT` | Exclude a term | `q=tesla NOT twitter` |
| Parentheses | Group expressions | `q=tesla AND (model3 OR cybertruck) NOT stock` |

---

---

## Response

### Success Response (`200 OK`)

```json
{
  "status": "ok",
  "totalResults": 4823,
  "articles": [
    {
      "source": {
        "id": "the-verge",
        "name": "The Verge"
      },
      "author": "Jane Smith",
      "title": "Tesla unveils new Model S update",
      "description": "A snippet or short description of the article content.",
      "url": "https://www.theverge.com/2026/02/14/...",
      "urlToImage": "https://cdn.theverge.com/images/example.jpg",
      "publishedAt": "2026-02-14T10:30:00Z",
      "content": "The first 200 characters of the article body are returned here..."
    }
  ]
}
```

### Response Fields

| Field | Type | Description |
|---|---|---|
| `status` | `string` | Request status. `ok` on success, `error` on failure. |
| `totalResults` | `integer` | Total number of results available for the query. |
| `articles` | `array` | List of article objects (see below). |

### Article Object Fields

| Field | Type | Description |
|---|---|---|
| `source.id` | `string` | Unique identifier for the news source. May be `null`. |
| `source.name` | `string` | Display name of the news source. |
| `author` | `string` | Author of the article. May be `null`. |
| `title` | `string` | Headline or title of the article. |
| `description` | `string` | Short snippet or summary of the article. |
| `url` | `string` | Direct URL to the full article. |
| `urlToImage` | `string` | URL of a relevant image for the article. May be `null`. |
| `publishedAt` | `string` | Publication date and time in UTC (ISO 8601 format). |
| `content` | `string` | Unformatted article body, **truncated to 200 characters**. |

> 💡 `content` is always truncated. To access the full article text, follow the `url` field.

---

## Error Responses

| HTTP Status | Code | Description |
|---|---|---|
| `400` | `badRequest` | Missing or misconfigured parameter. |
| `401` | `apiKeyInvalid` | API key missing or invalid. |
| `401` | `apiKeyDisabled` | API key has been disabled by the administrator. |
| `429` | `rateLimited` | Too many requests — you have exceeded your rate limit. |
| `500` | `serverError` | Unexpected server-side error. |

### Error Response Body

```json
{
  "status": "error",
  "code": "apiKeyInvalid",
  "message": "Your API key is invalid. Head to https://newsapi.org to create a free API key."
}
```

---

## Pagination

Use `pageSize` and `page` together to page through large result sets:

```
GET /v2/everything?q=tesla&pageSize=20&page=2&apiKey=YOUR_API_KEY
```

- Default page size is **20**, maximum is **100**.
- Calculate total pages: `Math.ceil(totalResults / pageSize)`.

---

## Rate Limits & Plan Notes

| Plan | Rate Limit | Historical Data |
|---|---|---|
| Developer (Free) | 100 requests / 24 hours | 1 month |
| Business | Higher limits | Up to 5 years |

> 💡 On the free plan, results are delayed and limited in history. Upgrade at [newsapi.org/pricing](https://newsapi.org/pricing) for production use.

---

## Notes

- At least one of `q`, `sources`, or `domains` is **required** — requests without any of these will return an error.
- `sources` and `domains` **cannot** be combined with `country` (that parameter is only for `/v2/top-headlines`).
- All `q` values must be **URL-encoded** when passed in the query string.
- Dates must be in **ISO 8601** format: `YYYY-MM-DD` or `YYYY-MM-DDTHH:MM:SS`.

---

## Related Endpoints

| Endpoint | Description |
|---|---|
| `GET /v2/top-headlines` | Live breaking headlines by country, category, or source. |
| `GET /v2/sources` | List all available news sources with metadata. |

---

*Documentation based on [NewsAPI.org](https://newsapi.org/docs). API version: v2.*
