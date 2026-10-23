# MatBroker

A World of Warcraft Forever addon. Tells you where every mat should go, what it's worth, and what to craft next.

- **Routing.** Every herb, skin, cloth, ore and enchanting mat gets a tooltip line naming the alt that needs it, or marking it surplus for the auction house.
- **Mailbox.** A panel beside the mailbox lists what to send to whom and fills the mail, using Forever's first-and-last names. Unbound greens queue to your chosen AH seller.
- **Prices.** Enchanting mat prices from your AH scans, Auctionator or manual values; disenchant value and max buy price on gear tooltips.
- **Guides.** Leveling guides for Alchemy, Leatherworking, Tailoring, Enchanting, Blacksmithing and Mining, docked beside the profession window.

`/mb` opens the window. `/mb help` lists the rest.

## Releasing

1. Bump `## Version` in `MatBroker.toc` and note the changes in the commit.
2. `git tag v1.0.1 && git push --tags`
3. The GitHub Action packages the addon and uploads it to CurseForge. The tag's commit message is the changelog.

Needs the `CF_API_KEY` repository secret (a CurseForge API token) and `## X-Curse-Project-ID` in the TOC.

## Credits

Leveling routes follow the [wow-professions.com](https://www.wow-professions.com/forever) Forever guides. Disenchant tables from [warcraft.wiki.gg](https://warcraft.wiki.gg/wiki/Disenchanting_tables), CC BY-SA.
