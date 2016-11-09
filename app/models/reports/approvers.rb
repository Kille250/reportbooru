module Reports
  class Approvers < Uploads
    include Concerns::Statistics

    def sort_key
      :total
    end

    def version
      1
    end

    def html_template
      return <<-EOS
%html
  %head
    %title Approver Report
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
      %caption Approvers over past thirty days (minimum approvals is #{min_approvals})
      %thead
        %tr
          %th User
          %th Total
          %th Del
          %th Del Conf
          %th Unq Flag
          %th S
          %th Q
          %th E
          %th Med Score
          %th Neg Conf
          %th Unq Downvote
      %tbody
        - data.each do |datum|
          %tr
            %td
              %a{:class => "user-\#{datum[:level]}", :href => "https://danbooru.donmai.us/users/\#{datum[:id]}"}= datum[:name]
            %td= datum[:total]
            %td= datum[:deleted]
            %td= datum[:del_conf]
            %td= datum[:uniq_flaggers]
            %td= datum[:safe]
            %td= datum[:questionable]
            %td= datum[:explicit]
            %td= datum[:med_score]
            %td= datum[:neg_conf]
            %td= datum[:uniq_downvoters]
    %p= "Since #{date_window.utc} to #{Time.now.utc}"
EOS
    end

    def candidates
      DanbooruRo::Post.where("created_at > ? and approver_id is not null", date_window).group("approver_id").having("count(*) > ?", min_approvals).pluck(:approver_id)
    end

    def report_name
      "approvers"
    end

    def min_approvals
      50
    end

    def calculate_data(user_id)
      user = DanbooruRo::User.find(user_id)
      name = user.name
      total = DanbooruRo::Post.where("created_at > ?", date_window).where(approver_id: user.id).count
      deleted = DanbooruRo::Post.where("created_at > ?", date_window).where(approver_id: user.id, is_deleted: true).count
      safe = DanbooruRo::Post.where("created_at > ?", date_window).where(approver_id: user.id, rating: "s").count
      questionable = DanbooruRo::Post.where("created_at > ?", date_window).where(approver_id: user.id, rating: "q").count
      explicit = DanbooruRo::Post.where("created_at > ?", date_window).where(approver_id: user.id, rating: "e").count
      med_score = "%.2f" % DanbooruRo::Post.select_value_sql("select percentile_cont(0.50) within group (order by score) from posts where created_at >= ? and approver_id = ?", date_window, user.id).to_f
      del_conf = "%.1f" % deletion_confidence_interval_for(user_id, date_window, :approver_id)
      neg_conf = "%.1f" % negative_score_confidence_interval_for(user_id, date_window, :approver_id)
      uniq_flaggers = DanbooruRo::PostFlag.joins("join posts on post_flags.post_id = posts.id").where("posts.created_at > ? and posts.is_deleted = true and posts.approver_id = ?", date_window, user_id).distinct.count("post_flags.creator_id")
      uniq_downvoters = DanbooruRo::PostVote.joins("join posts on post_votes.post_id = posts.id").where("posts.created_at > ? and post_votes.score < 0 and posts.approver_id = ?", date_window, user_id).distinct.count("post_votes.user_id")

      return {
        id: user_id,
        name: name,
        level: user.level,
        total: total,
        deleted: deleted,
        safe: safe,
        questionable: questionable,
        explicit: explicit,
        med_score: med_score,
        del_conf: del_conf,
        neg_conf: neg_conf,
        uniq_flaggers: uniq_flaggers,
        uniq_downvoters: uniq_downvoters
      }
    end
  end
end