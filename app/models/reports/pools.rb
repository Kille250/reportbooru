module Reports
  class Pools < Base
    def version
      1
    end

    def min_changes
      10
    end

    def report_name
      "pools"
    end

    def sort_key
      :total
    end
    
    def html_template
      return <<-EOS
%html
  %head
    %title Pool Report
    %meta{:name => "viewport", :content => "width=device-width, initial-scale=1"}
    %script{:src => "/reports/assets/jquery-3.1.1.slim.min.js"}
    %script{:src => "/reports/assets/jquery.tablesorter.min.js"}
    %link{:rel => "stylesheet", :href => "/reports/assets/pure.css"}
    :javascript
      $(function() {
        $("#report").tablesorter();
      });
  %body
    %table{:id => "report", :class => "pure-table pure-table-bordered pure-table-striped"}
      %caption Pools (over past thirty days, minimum count is #{min_changes})
      %thead
        %tr
          %th User
          %th Level
          %th Total
          %th Creates
          %th Adds
          %th Removes
          %th Orders
      %tbody
        - data.each do |datum|
          %tr
            %td
              %a{:class => "user-\#{datum[:level]}", :href => "https://danbooru.donmai.us/users/\#{datum[:id]}"}= datum[:name]
            %td= datum[:level_string]
            %td= datum[:total]
            %td= datum[:create]
            %td= datum[:add]
            %td= datum[:remove]
            %td= datum[:order]
EOS
    end

    def find_previous(version)
      DanbooruRo::PoolVersion.where("pool_id = ? and updated_at < ?", version.pool_id, version.updated_at).order("updated_at desc, id desc").first
    end

    def find_versions(user_id)
      DanbooruRo::PoolVersion.where("updater_id = ? and updated_at > ?", user_id, date_window)
    end

    def calculate_data(user_id)
      user = DanbooruRo::User.find(user_id)
      total = 0
      create = 0
      add = 0
      remove = 0
      order = 0

      find_versions(user_id).find_each do |version|
        total += 1
        version_post_ids = version.post_ids.scan(/\d+/)
        prev = find_previous(version)

        if prev.nil?
          create += 1
        else
          prev_post_ids = prev.post_ids.scan(/\d+/)

          if (version_post_ids - prev_post_ids).any?
            add += 1
          end

          if (prev_post_ids - version_post_ids).any?
            remove += 1
          end

          if (prev_post_ids & version_post_ids).size == prev_post_ids.size
            order += 1
          end
        end
      end

      return {
        id: user.id,
        name: user.name,
        level: user.level,
        level_string: user.level_string,
        total: total,
        create: create,
        add: add,
        remove: remove,
        order: order
      }
    end
    
    def candidates
      DanbooruRo::PoolVersion.where("updated_at > ?", date_window).group("updater_id").having("count(*) > ?", min_changes).pluck(:updater_id)
    end
  end
end
