# Script is based on what I found here: https://medium.com/ahmadaassaf/mass-cleaning-and-monitoring-of-slack-channels-8800f6567b39
# Original script was takend from the article and updated to use the new conversations method in the Slack API as well as account for pagination
# Script requires that you have jq installed.

# Slack API Token
TOKEN=''

# Slack API method.
# conversations.list is used to list all conversations.  
# exclude_archived=true - excludes archived channels
# limit=1000 - limit of results.  Default limit is 100.  Max limit is 1000
# types=public_channel - type of conversations to list. Default type is public_chanel
# cursor=  - pagination token used for when there are more results than limit

# Pull of first page of results
CONVERSATION_URL='https://slack.com/api/conversations.list';
curl -sS "$CONVERSATION_URL?token=$TOKEN&exclude_archived=true&limit=1000&types=public_channel" > /tmp/channels.list

# Select channels where num_members == 0
IDS=$(cat /tmp/channels.list | jq '.channels[] | select(.num_members == 0) | .id' | sed -e 's/"//g')

# Select token for pagination of results
NEXTPAGE=$(cat /tmp/channels.list | jq '.response_metadata | .next_cursor' | sed -e 's/"//g')
LASTPAGE=""

# $NEXTPAGE should be empty when there are no more paginated results.
# Loop through results until we get to the end. 
while [ "$NEXTPAGE" != "" ]; do

    #loop through channels where num_members == 0 and archive them.
    for ID in $IDS; do
        ARCHIVE_URL="https://slack.com/api/conversations.archive?token=$TOKEN&channel=$ID"
  
        echo $ARCHIVE_URL
        # the echo above is just to provide the URLs for the api calls to archive channels.  To actually archive the channels you should uncomment the curl below.
        # curl "$ARCHIVE_URL"
    done
    
    # Set the next page cursor to the value found at the end of the list.
    curl -sS "$CONVERSATION_URL?token=$TOKEN&exclude_archived=true&limit=1000&types=public_channel&cursor=$NEXTPAGE" > /tmp/channels.list
    NEXTPAGE=$(cat /tmp/channels.list | jq '.response_metadata | .next_cursor' | sed -e 's/"//g')
done
