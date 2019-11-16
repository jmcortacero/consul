require "csv"

namespace :db do
  desc "Import data from the CSV files"
  task alan_turing: :environment do
    puts Time.current
    print "Adjusting Settings: "
    Setting["feature.featured_proposals"] = true
    Setting["proposal_notification_minimum_interval_in_days"] = 0
    puts "done!"

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
      print "." if (proposal.id % 100) == 0
    end
    puts "\nProposals created!"

    puts "Asigning Users to Proposals"
    User.create!(username: "Usuario eliminado",
                 email: "usuario_eliminado@consul.dev",
                 password: "12345678",
                 password_confirmation: "12345678",
                 confirmed_at: Time.current,
                 terms_of_service: "1")
    user_deleted_id = User.last.id

    csv_file = "lib/tasks/alan_turing/proposals-users-full.csv"
    CSV.foreach(csv_file, col_sep: ";", headers: true) do |line|
      attributes = line.to_hash
      if Proposal.find_by_id(attributes["proposal"])
        proposal = Proposal.find(attributes["proposal"])
        if attributes["usernumber"].present?
          unless User.find_by_id(attributes["usernumber"])
            User.create!(id: attributes["usernumber"],
                       username: "usuario_#{attributes["usernumber"]}",
                       email: "usuario_#{attributes["usernumber"]}@consul.dev",
                       password: "12345678",
                       password_confirmation: "12345678",
                       confirmed_at: Time.current,
                       terms_of_service: "1")
          end
          proposal.update_columns author_id: attributes["usernumber"]
        else
          proposal.update_columns author_id: user_deleted_id
        end
        print "." if (proposal.id % 100) == 0
      end
    end
    puts "\nUsers assigned to Proposals!"

    puts "Creating Tags"
    csv_file = "lib/tasks/alan_turing/tags.csv"
    CSV.foreach(csv_file, col_sep: ";", headers: true) do |line|
      unless Tag.find_by_name(line.to_hash["name"])
        if line.to_hash["name"].present?
          tag = Tag.create!(line.to_hash)
          print "." if (tag.id % 100) == 0
        end
      end
    end
    puts "\nTags created!"

    puts "Asigning Tags to Proposals"
    ids = {
      "4995" => "3046",
      "6473" => "93",
      "6488" => "1988",
      "6509" => "113",
      "7258" => "3990",
      "7259" => "111",
      "7262" => "1509",
      "7263" => "148",
      "7276" => "6659"
    }
    csv_file = "lib/tasks/alan_turing/tagging.csv"
    CSV.foreach(csv_file, col_sep: ";", headers: true) do |line|
      unless line.to_hash["tag_id"].to_i == 6622 # it's a tag without name
        attributes = line.to_hash
        attributes["tag_id"] = ids[attributes["tag_id"]] if ids[attributes["tag_id"]]
        if attributes["taggable_type"] == "Proposal"
          attributes["tag_id"] = attributes["tag_id"].to_i
          attributes["taggable_id"] = attributes["taggable_id"].to_i
          attributes["context"] = "tags"
          tagging = Tagging.create!(attributes)
          print "." if (tagging.id % 100) == 0
        end
      end
    end
    puts "\nTags assigned to Proposals!"

    puts "Creating Comments"
    users_id = User.pluck(:id).to_a
    csv_file = "lib/tasks/alan_turing/comments.csv"
    CSV.foreach(csv_file, col_sep: ";", headers: true) do |line|
      attributes = line.to_hash
      if attributes["commentable_type"] == "Proposal"
        attributes["user_id"] = users_id.sample
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
    puts Time.current
  end
end
