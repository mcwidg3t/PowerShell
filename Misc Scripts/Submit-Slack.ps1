Function Submit-Slack
{
    <# 
    .SYNOPSIS
    Posts an entry to a Slack Channel

    .DESCRIPTION
    Posts an entry to a Slack Channel.  Channel name, username and message can all be specified.  Pulls an icon for the post from imgur.  Should be moved to a Norbord web server at some point.

    .EXAMPLE
    Submit-Slack -Username 'powershell-bot' -Channel '#powershell' -Message 'Hello there!'
    This command posts the message 'Hello there!' to the channel #powershell under the user 'powershell-bot'
    #>

    [cmdletbinding()]
    Param(
        [Parameter(Mandatory=$True)][String]$Message,
        [String]$Channel = '<channelname>',
        [String]$Username = '<usrename for post>',
        [Parameter(ParameterSetName="Icon_Emoji")][String]$IconEmoji,
        [Parameter(ParameterSetName="Icon_Url")][String]$IconURL
        )
    
    $slackhostname = "<your network>.slack.com"
    $slacktoken = "<your slack token>"
    $slackchannel = $Channel
    $slackbotname = $Username
    $psicon = "<your default avatar icon.png>"

    $payload = @{
	    text=$Message;
        channel=$slackchannel;
	    username=$slackbotname
    }

    # If statement to sort out icon
    # If emoji or url specified as icon use then, otherwise use the default $psicon
    If ($IconEmoji)
        {
            $payload.Add("icon_emoji", $iconemoji)
        }
        ElseIf ($IconURL)
            {
                $payload.Add("icon_url", $iconemoji)
            }
        Else
            {
                $payload.Add("icon_url", $psicon)
    } # End if statement for icon

    $slackuri = "https://" + $slackhostname + "/services/hooks/incoming-webhook?token=" + $slacktoken 
    #$payload
    Invoke-RestMethod -Uri $slackuri -Method Post -Body (ConvertTo-Json $payload)
}