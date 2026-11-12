# The benchmark's /up — same body as snails' Snails::HealthController so the
# comparison measures the framework path, not a different response shape.
class UpController < ActionController::API
  def show
    render json: { "status" => "ok" }
  end
end
