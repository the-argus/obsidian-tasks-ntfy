# obsidian-tasks-ntfy

A server which analyzes an obsidian vault and sends notifications to your
devices based on TODOs. Uses the obsidian-tasks TODO format.

provides ``notify-tasks``

## ``notify-tasks`` usage

```txt
notify-tasks [notes] [ntfy url]

    notes:
        A path to your obsidian vault or markdown notes.

        Example: ~/notes/obsidian
    ntfy url:
        The url with the domain of your ntfy server (usually ntfy.sh) and the
        desired topic. Needs explicit https or http format.

        Example: https://ntfy.sh/mytopic
```

## how to subscribe

Once you have set up notify-tasks, you will want to subscribe to the ntfy topic
on your devices, so you actually recieve the notifications. See [Subscribe to a topic](https://ntfy.sh/#subscribe).

## tasks spec

waiting on [this issue I made](https://github.com/obsidian-tasks-group/obsidian-tasks/issues/1656)
