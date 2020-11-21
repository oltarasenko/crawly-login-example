defmodule QuotesSpider do
  use Crawly.Spider

  alias Crawly.Utils

  @impl Crawly.Spider
  def base_url(), do: "http://quotes.toscrape.com/"

  @impl Crawly.Spider
  def init() do
    session_cookie = get_session_cookie("any_username", "any_password")

    [
      start_requests: [
        Crawly.Request.new("http://quotes.toscrape.com/", [{"Cookie", session_cookie}])
      ]
    ]
  end

  @impl Crawly.Spider
  def parse_item(response) do
    {:ok, document} = Floki.parse_document(response.body)

    # Extract request from pagination links
    requests =
      document
      |> Floki.find("li.next a")
      |> Floki.attribute("href")
      |> Utils.build_absolute_urls(response.request_url)
      |> Utils.requests_from_urls()

    items =
      document
      |> Floki.find(".quote")
      |> Enum.map(&parse_quote_block/1)

    %{
      :requests => requests,
      :items => items
    }
  end

  defp parse_quote_block(block) do
    %{
      quote: Floki.find(block, ".text") |> Floki.text(),
      author: Floki.find(block, ".author") |> Floki.text(),
      tags: Floki.find(block, ".tags a.tag") |> Enum.map(&Floki.text/1),
      goodreads_link:
        Floki.find(block, "a:fl-contains('(Goodreads page)')")
        |> Floki.attribute("href")
        |> Floki.text()
    }
  end

  def get_session_cookie(username, password) do
    action_url = "http://quotes.toscrape.com/login"
    response = Crawly.fetch(action_url)

    # Extract cookie from headers
    {{"Set-Cookie", cookie}, _headers} = List.keytake(response.headers, "Set-Cookie", 0)

    # Extract CSRF token from body
    {:ok, document} = Floki.parse_document(response.body)

    csrf =
      document
      |> Floki.find("form input[name='csrf_token']")
      |> Floki.attribute("value")
      |> Floki.text()

    # Prepare and send the request. The given login form accepts any
    # login/password pair
    req_body =
      %{
        "username" => username,
        "password" => password,
        "csrf_token" => csrf
      }
      |> URI.encode_query()

    {:ok, login_response} =
      HTTPoison.post(action_url, req_body, %{
        "Content-Type" => "application/x-www-form-urlencoded",
        "Cookie" => cookie
      })

    {{"Set-Cookie", session_cookie}, _headers} =
      List.keytake(login_response.headers, "Set-Cookie", 0)

    session_cookie
  end
end
