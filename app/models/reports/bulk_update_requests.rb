=begin
from brokeneagle98:

Total: total BUR created/user
Approved: total where 'status' == 'approved'
Rejected: total where 'rejected' == 'rejected'
=end

module Reports
	class BulkUpdateRequests < Base
    def version
      2
    end

    def min_changes
      2
    end

    def report_name
      "bulk_update_requests"
    end

    def sort_key
      :count
    end

    def html_template
      return <<-EOS
%html
  %head
    %title Bulk Update Request Report
    %meta{:name => "viewport", :content => "width=device-width, initial-scale=1"}
    %script{:src => "/user-reports/assets/jquery-3.1.1.slim.min.js"}
    %script{:src => "/user-reports/assets/jquery.tablesorter.min.js"}
    %link{:rel => "stylesheet", :href => "/user-reports/assets/pure.css"}
    :javascript
      $(function() {
        $("#report").tablesorter();
      });
  %body
    %table{:id => "report", :class => "pure-table pure-table-bordered pure-table-striped"}
      %caption Bulk Update Requests (over past thirty days, minimum count is #{min_changes})
      %thead
        %tr
          %th User
          %th Level
          %th Count
          %th Approved
          %th Rejected
      %tbody
        - data.each do |datum|
          %tr
            %td
              %a{:class => "user-\#{datum[:level]}", :href => "https://danbooru.donmai.us/users/\#{datum[:id]}"}= datum[:name]
            %td= datum[:level_string]
            %td= datum[:count]
            %td= datum[:approved]
            %td= datum[:rejected]
    %p= "Since \#{date_window.utc} to \#{Time.now.utc}"
EOS
    end

    def calculate_data(user_id)
      user = DanbooruRo::User.find(user_id)

      return {
        id: user.id,
        name: user.name,
        level: user.level,
        level_string: user.level_string,
        count: DanbooruRo::BulkUpdateRequest.where("created_at > ? and user_id = ?", date_window, user.id).count,
        approved: DanbooruRo::BulkUpdateRequest.where("created_at > ? and user_id = ? and status = ?", date_window, user.id, "approved").count,
        rejected: DanbooruRo::BulkUpdateRequest.where("created_at > ? and user_id = ? and status = ?", date_window, user.id, "rejected").count
      }
    end

		def candidates
			DanbooruRo::BulkUpdateRequest.where("updated_at > ?", date_window).group("user_id").having("count(*) >= ?", min_changes).pluck(:user_id)
		end
	end
end

