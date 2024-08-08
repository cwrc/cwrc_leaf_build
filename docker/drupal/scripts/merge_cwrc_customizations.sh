
merge_composer_json() {
    composer_json_path="/var/www/drupal/composer.json"
    # append to .repositories[] the CWRC customization: islandora bagger to the list of repositories if it doesn't already exist
    # could try an `jq` with `| has(.url)` and if/else to shorten this code
    # jq 'if (.repositories[] | select(.url=="https://github.com/cwrc/islandora_bagger_integration.git") | has(.url)) then ${new_repo} else . end'
    ret=$(jq -e '.repositories[] | select(.url=="https://github.com/cwrc/islandora_bagger_integration.git")' ${composer_json_path} >> /dev/null)
    if [ $? == 0 ] ; then
        echo "URL Found";
    else
        echo "URL Not Found";
        jq '.repositories += [{"type": "git", "url": "https://github.com/cwrc/islandora_bagger_integration.git", "no-api": true}]' ${composer_json_path} > ${composer_json_path}.new && \
        mv ${composer_json_path} ${composer_json_path}.bak && \
        mv ${composer_json_path}.new ${composer_json_path}
    fi
}

merge_composer_json