// aria-* = screen reader (high-level, oversimplified)
const search = document.querySelector("textarea,input[aria-label=Search]")
// textarea,input[name=q] is also an option, but it also looks more likely to change/be duplicated
// search.value contains the search query (after rendering js? who knows, but the HTML already has it)

// thankfully, we don't actually need this - this time.
const infobar = document.querySelector("div.kp-wholepage-osrp");
// infobar contains the "Vincent Van Gogh (Dutch painter)"

const kgStuff = {

}


// const botstuff = document.querySelector("div#botstuff") // anti-bot stuff?

// const artblock = document.querySelector("div[data-hveid=2ahUKEwjK-K-JwLWKAxXcQTABHePpOFoQy9oBKAB6BAg8EAA]"); // yeah nah not this

// const artblockOnlyDirect = document.querySelector("div[attrid=kc:/visual_art/visual_artist:works]") // not this either



// can easily be deprecated if Google decides to recompile with more mangling and nesting
// const artworkParent = artworkResults.parentElement.parentElement;



function scrapeItems() {
  const results = document.querySelector("div#search"); // not a fan, but this seems stable

  const artworkResults = results.querySelector("g-loading-icon").nextElementSibling; // Interesting.
  // works on live too, hmm
  // but NOT on discography
  //  NOTE: discography uses a different block - the GRID view, not a carousel view - (wp-grid-view, wp-grid-tile)
  //    this grid view, given the more predictable element name, has different approaches
  // same thing for filmography, games, books

  const items = Array.from(artworkResults.querySelectorAll("img"))
    .map(img => {
      const details = img.nextElementSibling; // relative HTML positioning, can be deprecated easily
      const hasExtensions = details.lastElementChild?.textContent ?? false;
      return {
        name: details.firstElementChild?.textContent,
        extensions: hasExtensions
          ? [
            details.lastElementChild?.textContent
          ]
          : undefined,
        // string replace to match expected
        link: img.parentElement.href.replace("file://", "https://www.google.com"),
        image: img.getAttribute("data-src") ?? img.src,
      }
    });

  return { artworks: items }
}