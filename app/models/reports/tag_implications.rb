=begin
from brokeneagle98:

Total: total implications created/user
Approved: total where 'status' == 'active'
=end

module Reports
	class TagImplications < Base
    def version
      2
    end

    def min_changes
      2
    end

    def report_name
      "tag_implications"
    end

    def sort_key
      :count
    end

    def html_template
      return <<-EOS
%html
  %head
    %title Tag Implications Report
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
      %caption Tag implications (over past thirty days, minimum count is #{min_changes})
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
        count: DanbooruRo::TagImplication.where("created_at > ? and creator_id = ?", date_window, user.id).count,
        approved: DanbooruRo::TagImplication.where("created_at > ? and creator_id = ? and status = ?", date_window, user.id, "active").count,
        rejected: DanbooruRo::TagImplication.where("created_at > ? and creator_id = ? and status = ?", date_window, user.id, "deleted").count
      }
    end

		def candidates
			DanbooruRo::TagImplication.where("updated_at > ?", date_window).group("creator_id").having("count(*) >= ?", min_changes).pluck(:creator_id)
		end
	end
end
