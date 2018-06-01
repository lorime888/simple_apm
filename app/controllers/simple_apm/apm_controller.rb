require_dependency "simple_apm/application_controller"

module SimpleApm
  class ApmController < ApplicationController
    include SimpleApm::ApplicationHelper
    before_action :set_query_date

    def dashboard
      d = SimpleApm::RedisKey.query_date == Time.now.strftime('%Y-%m-%d') ? Time.now.strftime('%H:%M') : '23:50'
      data = SimpleApm::Hit.chart_data(0, d)
      @x_names = data.keys.sort
      @time_arr = @x_names.map{|n| data[n][:hits].to_i.zero? ? 0 : (data[n][:time].to_f/data[n][:hits].to_i).round(3) }
      @hits_arr = @x_names.map{|n| data[n][:hits] rescue 0}
    end

    def index
      respond_to do |format|
        format.json do
          @slow_requests = SimpleApm::SlowRequest.list(params[:count]||200).map do |r|
            request = r.request
            [
              link_to(time_label(request.started), show_path(id: request.request_id)),
              link_to(request.action_name, action_info_path(action_name: request.action_name)),
              sec_str(request.during),
              sec_str(request.db_runtime),
              sec_str(request.view_runtime),
              request.host,
              request.remote_addr
            ]
          end
          render json: {data: @slow_requests}
        end
        format.html
      end
    end

    def show
      @request = SimpleApm::Request.find(params[:id])
    end

    def actions
      @actions = SimpleApm::Action.all_names.map{|n| SimpleApm::Action.find(n)}
    end

    def action_info
      @action = SimpleApm::Action.find(params[:action_name])
    end

    def change_date
      session[:apm_date] = params[:date]
      redirect_to request.referer
    end

    def set_apm_date
      # set_query_date
      redirect_to action: :dashboard
    end

    private
    def set_query_date
      session[:apm_date] = params[:apm_date] if params[:apm_date].present?
      SimpleApm::RedisKey.query_date = session[:apm_date]
    end

    def link_to(name, url)
      "<a href=#{url.to_json}>#{name}</a>"
    end
  end
end
