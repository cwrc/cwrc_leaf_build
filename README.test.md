# How to test

## Act testing GitHub Actions

https://nektosact.com/usage/index.html

### To simulate a git tag

* Create a file with the following:

```json
{
  "ref": "refs/tags/v1.99.91"
}
```

* `../tmp2/act -W .github/workflows/push.yml -s GITHUB_TOKEN push -e /tmp/event_tag.json`

### To simulate a git branch

* Create a file with the following (might work if currently in a branch)

``` json
{
  "ref": "refs/heads/act-test-leaf"
}
```

* `../tmp2/act -W .github/workflows/push.yml -s GITHUB_TOKEN push -e /tmp/event_branch.json`
