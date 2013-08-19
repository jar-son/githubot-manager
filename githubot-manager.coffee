# Description:
#   Lets git some github action in here
#
# Commands:
#	git list pull requests for <repo>
#	git merge pull request <pull_request> for <repo>
#	git list members of <org>
#	git list issues for <repo>
#	git create issue for <repo> with title <title> and body <issue_body>
#	git close issue <issue_number> for <repo>
#   git list my repos
#	git list repos for <git-user>
#	git list list org repos for <git-org>
#	git list my gists
#	git create gist <filename> with contents "<contents>"
#	git delete gist <gistID>
#
# Configuration:
#   HUBOT_GITHUB_TOKEN - your token for github
#	HUBOT_GITHUB_USER - github user
#
# Depencencys
#   githubot
#
# Notes:
#   To get a token: curl -i https://api.github.com/authorizations -d '{"scopes":["repo","gist"]}' -u "username"
#   This lets you merge pull requests, list members/issues/and pulls for a github repo/org

mergedPullRequests = [
	"http://24.media.tumblr.com/tumblr_m53neamBi61rwqv34o1_500.gif",
	"http://i.imgur.com/9WdX0aW.gif",
	"http://i.imgur.com/qUOTPXW.gif",
	"http://i.imgur.com/SKTjikk.gif",
	"http://i.imgur.com/hQtLGCx.gif",
	"http://i.imgur.com/9ahmzKV.gif"
]

errors = [
	"http://km.support.apple.com/library/APPLE/APPLECARE_ALLGEOS/TS3742/en_US/TS3742-ML_Panic-001-en.png",
	"I'm sorry Dave, I'm afraid I can't do that",
	"http://technologizer.files.wordpress.com/2008/09/sadmac.png?w=225&h=208",
	"http://24.media.tumblr.com/tumblr_m4i8brl8wB1qg3muyo1_500.gif",
	"http://cdn.uproxx.com/wp-content/uploads/2013/04/Annoying_no_gif.gif",
	"http://i.imgur.com/w1Y8UpE.jpg",
	"http://i.imgur.com/qtVfEYA.gif"
]

module.exports = (robot) ->
	github = require("githubot")(robot)

	github.handleErrors (response) ->
		robot.send null, errors[Math.floor(Math.random() * errors.length)]
		robot.send null, "#{key} - #{value}" for key, value of response

	robot.respond /git list pull request(s)? for (.+)/i, (msg) ->
		github.get "repos/#{msg.match[3]}/pulls", (pulls) ->
			msg.send "Pull requests for #{msg.match[3]}\n}"
			displayPull msg, pull for pull in pulls

	robot.respond /git merge pull request (\d+) for (.+)/i, (msg) ->
		github.request "put", "repos/#{msg.match[2]}/pulls/#{msg.match[1]}/merge", 
		{commit_message: "merged by #{robot.name}!"}, (merged) ->
			if  merged.merged
				msg.send msg.random mergedPullRequests
				msg.send "#{merged.message}"
			else
				msg.send "http://cdn.meme.li/i/ijx1g.jpg"

	robot.respond /git view issue (\d+) for (.+)/i, (msg) ->
		github.get "repos/#{msg.match[2]}/issues/#{msg.match[1]}", (issue) ->
			displayIssue msg, issue
			if issue.comments > 0
				github.get "repos/#{msg.match[2]}/issues/#{msg.match[1]}/comments", (comments) ->
					displayComment msg, comment for comment in comments
			
			
	robot.respond /git list my repos/i, (msg) ->
		github.get "users/#{process.env.HUBOT_GITHUB_USER}/repos", { type: "all"} , (repos) ->
			msg.send "#{repo.name}" for repo in repos

	robot.respond /git list repos for (.+)/i, (msg) ->
		github.get "users/#{msg.match[1]}/repos", { type: "all" }, (repos) ->
			msg.send "Repos:\n"
			msg.send "#{repo.name}" for repo in repos

	robot.respond /git list org repos for (.+)/i, (msg) ->
		github.get "orgs/#{msg.match[1]}/repos}", (repos) ->
			msg.send "Repos:\n"
			msg.send "#{repo.name}" for repo in repos

	robot.respond /git list members of (.+)/i, (msg) ->
		github.get "orgs/#{msg.match[1]}/members", (members) ->
			msg.send "Members:\n"
			msg.send "#{member.login}" for member in members

	robot.respond /git list issue(s)? for (.+)/i, (msg) ->
		github.get "repos/#{msg.match[2]}/issues", (issues) ->
			msg.send "Issues for #{msg.match[2]}:\n\n"
			displayIssue msg, issue for issue in issues

	robot.respond /git create issue for (.+) with title (.+) and body (.+)/i, (msg) ->
		repo 	= msg.match[1]
		title	= msg.match[2]
		body	= msg.match[3]

		data = { title: title, body: body }
		github.post "/repos/#{repo}/issues", data, (issue) ->
			msg.send "#{issue.user.login} created issue: #{issue.title}\n#{issue.body}\n#{issue.html_url}"

	robot.respond /git close issue (\d+) for (.+)/i, (msg) ->
		issueNumber = msg.match[1]
		repo 	    = msg.match[2]

		data = { state: "close"}
		github.request "patch", "repos/#{repo}/issues/#{issueNumber}", data, (issue) ->
			msg.send "Issue #{issueNumber} closed"
			msg.send "#{issue.html_url}"

	robot.respond /git create gist (.+) with contents "(.+)"/i, (msg) ->
		fileName = msg.match[1]
		contents = msg.match[2]
		data 	 = { public: true}

		data["files"] = {}
		data["files"][fileName] = {content: contents}

		github.post "gists", data, (gist) ->
			msg.send "gist created: #{gist.html_url}"

	robot.respond /git list my gists/i, (msg) ->
		github.get "gists", (gists) ->
			msg.send "#{gist.html_url}" for gist in gists

	robot.respond /git delete gist (\d+)/i, (msg) ->
		github.request "delete", "gists/#{msg.match[1]}", (deleted) ->
			msg.send "deleted gist"

	displayIssue = (msg, issue) ->
		msg.send "#{issue.title} - Created By: #{issue.user.login}"
		msg.send "comments: #{issue.comments}"
		msg.send "#{issue.html_url}"
		msg.send "-----------------"

	displayPull = (msg, pull) ->
		msg.send "#{pull.title} - Created By: #{pull.user.login}"
		msg.send "#{pull.html_url}"
		msg.send "-----------------"

	displayComment = (msg, comment) ->
		msg.send "#{comment["id"]} - #{comment.user.login}\n\t#{comment["body"]}"
