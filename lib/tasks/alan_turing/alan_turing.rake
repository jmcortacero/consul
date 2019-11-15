require "csv"

namespace :db do
  desc "Import data from the CSV files"
  task alan_turing: :environment do

    puts "Adjusting Settings: "
    Setting["feature.featured_proposals"] = true
    Setting["proposal_notification_minimum_interval_in_days"] = 0
    puts "done!"

    puts "Creating Users"
    (2..654722).each do |i|
      User.create!(username: "user_#{i}",
                   email: "user_#{i}@consul.dev",
                   password: "12345678",
                   password_confirmation: "12345678",
                   confirmed_at: Time.current,
                   terms_of_service: "1")
      print "." if (i % 100) == 0
    end
    User.create!(username: "User deleted",
                   email: "user_deleted@consul.dev",
                   password: "12345678",
                   password_confirmation: "12345678",
                   confirmed_at: Time.current,
                   terms_of_service: "1")
    puts "\nUsers created!"

    puts "Creating Proposals"
    csv_file = "lib/tasks/alan_turing/proposals.csv"
    description_max_length = Proposal.description_max_length
    CSV.foreach(csv_file, col_sep: ";", headers: true) do |line|
      attributes = line.to_hash
      attributes.delete("proceeding")
      attributes.delete("sub_proceeding")
      attributes["terms_of_service"] = "1"
      attributes["author_id"] = 1
      attributes["published_at"] = Time.current
      if attributes["description"].present?
        attributes["description"] = attributes["description"].truncate(description_max_length)
      end
      proposal = Proposal.create!(attributes)
      print "." if (proposal.id % 10) == 0
    end
    puts "\nProposals created!"

    puts "Asigning Users to Proposals"
    csv_file = "lib/tasks/alan_turing/proposals-users-full.csv"
    user_deleted_id = User.last.id
    CSV.foreach(csv_file, col_sep: ";", headers: true) do |line|
      attributes = line.to_hash
      proposal = Proposal.find(attributes["proposal"])
      if attributes["usernumber"].present?
        proposal.update_columns author_id: attributes["usernumber"]
      else
        proposal.update_columns author_id: user_deleted_id
      end
      print "." if (proposal.id % 10) == 0
    end
    puts "\nUsers assigned to Proposals!"

    puts "Creating Tags"
    csv_file = "lib/tasks/alan_turing/tags.csv"
    CSV.foreach(csv_file, col_sep: ";", headers: true) do |line|
      tag = Tag.create!(line.to_hash)
      print "." if (tag.id % 10) == 0
    end
    puts "\nTags created!"

    puts "Asigning Tags to Proposals"
    csv_file = "lib/tasks/alan_turing/tagging.csv"
    CSV.foreach(csv_file, col_sep: ";", headers: true) do |line|
      attributes = line.to_hash
      if attributes["taggable_type"] == "Proposal"
        attributes["tag_id"] = attributes["tag_id"].to_i
        attributes["taggable_id"] = attributes["taggable_id"].to_i
        attributes["context"] = attributes["taggable_type"]
        tagging = Tagging.create!(attributes)
        print "." if (tagging.id % 10) == 0
      end
    end
    puts "\nTags assigned to Proposals!"

    puts "Creating Comments"
    csv_file = "lib/tasks/alan_turing/comments.csv"
    CSV.foreach(csv_file, col_sep: ";", headers: true) do |line|
      attributes = line.to_hash
      if attributes["commentable_type"] == "Proposal"
        attributes["id"] = attributes["id"].to_i
        attributes["commentable_id"] = attributes["commentable_id"].to_i
        attributes["cached_votes_total"] = attributes["cached_votes_total"].to_i
        attributes["cached_votes_up"] = attributes["cached_votes_up"].to_i
        attributes["cached_votes_down"] = attributes["cached_votes_down"].to_i
        attributes["ancestry"] = attributes["ancestry"].to_i
        attributes["confidence_score"] = attributes["confidence_score"].to_i
        attributes.delete("created_at")
        comment = Comment.create!(attributes)
        print "." if (comment.id % 100) == 0
      end
    end
    puts "\nComments created!"
  end
end
