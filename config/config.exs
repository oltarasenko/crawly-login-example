use Mix.Config

config :crawly,
  closespider_timeout: 10,
  concurrent_requests_per_domain: 8,
  middlewares: [
    Crawly.Middlewares.DomainFilter,
    Crawly.Middlewares.UniqueRequest,
    Crawly.Middlewares.AutoCookiesManager,
    {Crawly.Middlewares.UserAgent, user_agents: ["Crawly Bot"]}
  ],
  pipelines: [
    {Crawly.Pipelines.Validate, fields: [:quote, :author, :tags]},
    Crawly.Pipelines.JSONEncoder,
    {Crawly.Pipelines.WriteToFile, extension: "json", folder: "/tmp"}
  ]
