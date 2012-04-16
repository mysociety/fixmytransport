atom_feed do |feed|
  feed.title(@title)
  feed.updated(@updated)
  @issues.each do |issue|
    if issue.is_a?(Campaign)
      feed.entry(issue) do |entry|
        entry.title issue.title + issue.feed_title_suffix
        entry.content(strip_tags(issue.description))
        entry.author do |author|
          author.name(issue.initiator.name)
        end
      end
    elsif issue.is_a?(Problem)
      feed.entry(issue) do |entry|
        entry.title issue.subject + issue.feed_title_suffix
        entry.content(strip_tags(issue.description))
        entry.author do |author|
          author.name(issue.reporter.name)
        end
      end
    end
  end
end
