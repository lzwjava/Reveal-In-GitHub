# Reaveal-In-Github

Xcode plugin to let you jump to Github History, Blame, PRs, Issues, Notifications of current repo in one second.

![plugin](https://cloud.githubusercontent.com/assets/5022872/10867703/96e980be-80ab-11e5-9aaa-a06ef476b7f7.gif)

My company work on Github. I open the Github a lot. Sometimes, I am editing on Xcode and do not understand some code, so I go to github to blame them. Sometimes, find the latest commits about a file to help me figure out how the code evolves. So I wonder is there a tool to help me quick open Github from Xcode. So I write this plugin. When you editing some source file on Xcode, it's easy to know which Github repo you are working on and know which file you are editing. So it makes sense to quickly jump to the file on Github, quickly jump to blame the current editing line on Github, quickly jump to the issues or prs of the current repo you are working on Xcode.

## Menu Items

<img width="700" alt="2015-11-01 12 56 35" src="https://cloud.githubusercontent.com/assets/5022872/10864813/5df3f05e-8034-11e5-9f3e-03ae3fbc3cfc.png">

It has six menu items:

 Menu Title     | Shortcut              | Github URL Pattern (When I'm editing LZAlbumManager.m Line 40)               
----------------|-----------------------|----------------------------------
 Setting	    |⌃⇧⌘S |
 Repo           |⌃⇧⌘R | https://github.com/lzwjava/LZAlbum
 Issues         |⌃⇧⌘I | https://github.com/lzwjava/LZAlbum/issues
 PRs            |⌃⇧⌘P | https://github.com/lzwjava/LZAlbum/pulls
 Quick File     |⌃⇧⌘Q | https://github.com/lzwjava/LZAlbum/blob/fd7224/LZAlbum/manager/LZAlbumManager.m#L40
 List History   |⌃⇧⌘L | https://github.com/lzwjava/LZAlbum/commits/fd7224/LZAlbum/manager/LZAlbumManager.m
 Blame          |⌃⇧⌘B | https://github.com/lzwjava/LZAlbum/blame/fd7224/LZAlbum/manager/LZAlbumManager.m#L40
 Notifications  |⌃⇧⌘N | https://github.com/leancloud/LZAlbum/notifications?all=1

The shortcuts are carefully designed. They will not confict to Xcode default shortcuts. The shortcut pattern is ⌃⇧⌘ + First Character of the menu title.

Blame (find who latestly modify current line):

![qq20151101-1 2x](https://cloud.githubusercontent.com/assets/5022872/10864851/a9124530-8035-11e5-8d67-ea73c9156d71.png)

When I don't understand some magic code, I use this to help me figure it out.

Current Repo's Pull Requests:

![qq20151101-5 2x](https://cloud.githubusercontent.com/assets/5022872/10864881/96279d84-8036-11e5-9799-61a27dd3a525.png)

Current Repo's Notifications(You need to watch the repo):

![qq20151101-6 2x](https://cloud.githubusercontent.com/assets/5022872/10864886/aa27ecd0-8036-11e5-929c-ea1adc106103.png)

## Customize

Sometimes, you may want to quickly jump to Wiki. Here is the way, open the setting:

<img width="500" alt="2015-11-01 12 56 35" src="https://cloud.githubusercontent.com/assets/5022872/10864939/fa83f286-8037-11e5-97d7-e9549485b11d.png">

For example, 

Quick file, the pattern and the actual url:

```
           {git_remote_url}       /blob/{commit}/          {file_path}         #{selection}    
https://github.com/lzwjava/LZAlbum/blob/fd7224/LZAlbum/manager/LZAlbumManager.m#L40-L43
```

The {commit} is the latest commit hash of current branch. It's better then use branch. Because branch's HEAD may be changed. So the code in #L40-L43 may also be changed.

So if you want to add a shortcut to current repo's wiki, just add a menu item and set the pattern to ` {git_remote_url}/wiki`.

In settings, `Clear Default Repos` say if you have multiple git remotes, when first time to trigger, it will ask you to choose one of them:

<img width="400" src="https://cloud.githubusercontent.com/assets/5022872/10865120/5794994a-803c-11e5-9527-965f7e617e8f.png">

Then the plugin remembers which you choose. So when you trigger the menu again, will open that remote repo as the default. The button `Clear Default Repos` will clear this setting, will ask you to select again.

## Install

Recomend install with Alcatraz,

![qq20151101-1 2x](https://cloud.githubusercontent.com/assets/5022872/10867743/0ce351c6-80ae-11e5-82e2-f740887153f7.jpg)

Or

1. Clone this repo.
2. Open `Reveal-In-Github.xcodeproj`, and build it.
3. Reveal-In-Github.xcplugin should locate at `~/Library/Application Support/Developer/Shared/Xcode/Plug-ins`
4. Restart Xcode
5. Open any Github Project and press ⌃⇧⌘B (Ctrl+Shift+Command+B) to blame the code.

## Credit

When at the course of developing it, find another plugin [ShowInGithub](https://github.com/larsxschneider/ShowInGitHub) do something similar. I learn some techique from it. Thanks for that.

## License

MIT