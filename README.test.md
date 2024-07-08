## Act testing GitHub Actions

https://nektosact.com/usage/index.html

To simulate 

* Create a file with the following:
```json
{
  "ref": "refs/tags/v1.99.91"
}
```

../tmp2/act -W .github/workflows/push.yml -s GITHUB_TOKEN push -e /tmp/event_tag.json

