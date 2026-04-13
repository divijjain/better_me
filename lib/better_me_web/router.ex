defmodule BetterMeWeb.Router do
  use BetterMeWeb, :router

  import BetterMeWeb.UserAuth

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {BetterMeWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug :fetch_current_scope_for_user
    plug BetterMeWeb.Plugs.RateLimit
  end

  pipeline :api do
    plug :accepts, ["json"]

    plug Corsica,
      origins: "*",
      allow_headers: ["authorization", "content-type", "accept"],
      allow_credentials: false

    plug BetterMeWeb.Plugs.ApiRateLimit
  end

  pipeline :api_authenticated do
    plug :accepts, ["json"]

    plug Corsica,
      origins: "*",
      allow_headers: ["authorization", "content-type", "accept"],
      allow_credentials: false

    plug BetterMeWeb.Plugs.ApiRateLimit
    plug BetterMeWeb.Plugs.BearerAuth
  end

  scope "/", BetterMeWeb do
    pipe_through :browser

    get "/", PageController, :home
  end

  scope "/api", BetterMeWeb.Api do
    pipe_through :api

    post "/auth/google", AuthController, :google
  end

  scope "/api", BetterMeWeb.Api do
    pipe_through :api_authenticated

    get "/habits", HabitsController, :index
    post "/habits", HabitsController, :create
    post "/habits/:habit_id/log", HabitsController, :log

    get "/health/metrics", HealthController, :index
    post "/health/metrics", HealthController, :create

    get "/workouts", WorkoutsController, :index
    post "/workouts", WorkoutsController, :create
    post "/workouts/:workout_id/exercises", WorkoutsController, :add_exercise
    post "/workouts/:workout_id/exercises/:exercise_id/sets", WorkoutsController, :log_set

    get "/todos", TodosController, :index
    post "/todos", TodosController, :create
    patch "/todos/:id/complete", TodosController, :complete
    delete "/todos/:id", TodosController, :delete

    get "/journal", JournalController, :index
    post "/journal", JournalController, :create
    put "/journal/:id", JournalController, :update
    delete "/journal/:id", JournalController, :delete

    get "/nutrition/summary", NutritionController, :daily_summary
    get "/nutrition/recipes", NutritionController, :recipes
    post "/nutrition/meals", NutritionController, :log_meal
    delete "/nutrition/meals/:id", NutritionController, :delete_meal

    post "/insights/ask", InsightsController, :ask
    get "/insights/quota", InsightsController, :quota
  end

  # Enable LiveDashboard and Swoosh mailbox preview in development
  if Application.compile_env(:better_me, :dev_routes) do
    # If you want to use the LiveDashboard in production, you should put
    # it behind authentication and allow only admins to access it.
    # If your application does not have an admins-only section yet,
    # you can use Plug.BasicAuth to set up some basic authentication
    # as long as you are also using SSL (which you should anyway).
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through :browser

      live_dashboard "/dashboard", metrics: BetterMeWeb.Telemetry
      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end
  end

  ## Authentication routes

  # Registration disabled — sign in via Google OAuth only
  # scope "/", BetterMeWeb do
  #   pipe_through [:browser, :redirect_if_user_is_authenticated]
  #   get "/users/register", UserRegistrationController, :new
  #   post "/users/register", UserRegistrationController, :create
  # end

  scope "/", BetterMeWeb do
    pipe_through [:browser, :require_authenticated_user]

    get "/users/settings", UserSettingsController, :edit
    put "/users/settings", UserSettingsController, :update
    get "/users/settings/confirm-email/:token", UserSettingsController, :confirm_email

    live_session :authenticated,
      on_mount: [{BetterMeWeb.UserAuth, :require_authenticated}] do
      live "/habits", HabitsLive.Index, :index
      live "/habits/new", HabitsLive.Form, :new
      live "/habits/:id", HabitsLive.Show, :show
      live "/habits/:id/edit", HabitsLive.Form, :edit

      live "/todos", TodosLive.Index, :index
      live "/todos/new", TodosLive.Form, :new
      live "/todos/:id/edit", TodosLive.Form, :edit

      live "/health", HealthLive.Index, :index
      live "/health/new", HealthLive.Form, :new
      live "/health/:id/edit", HealthLive.Form, :edit

      live "/workouts", WorkoutsLive.Index, :index
      live "/workouts/new", WorkoutsLive.Form, :new
      live "/workouts/:id", WorkoutsLive.Show, :show
      live "/workouts/:id/edit", WorkoutsLive.Form, :edit

      live "/nutrition", NutritionLive.Index, :index
      live "/profile", ProfileLive.Index, :index

      live "/ingredients", IngredientsLive.Index, :index
      live "/ingredients/new", IngredientsLive.Form, :new
      live "/ingredients/:id/edit", IngredientsLive.Form, :edit

      live "/recipes", RecipesLive.Index, :index
      live "/recipes/new", RecipesLive.Form, :new
      live "/recipes/:id", RecipesLive.Show, :show
      live "/recipes/:id/edit", RecipesLive.Form, :edit

      live "/journal", JournalLive.Index, :index
      live "/journal/new", JournalLive.Form, :new
      live "/journal/:id/edit", JournalLive.Form, :edit

      live "/insights", InsightsLive.Index, :index
      live "/analytics", AnalyticsLive.Index, :index
    end
  end

  scope "/", BetterMeWeb do
    pipe_through [:browser]

    get "/users/log-in", UserSessionController, :new
    post "/users/log-in", UserSessionController, :create
    delete "/users/log-out", UserSessionController, :delete
  end

  scope "/auth", BetterMeWeb do
    pipe_through [:browser]

    get "/google", GoogleOAuthController, :request
    get "/google/callback", GoogleOAuthController, :callback
  end
end
