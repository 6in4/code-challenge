import * as cheerio from "cheerio";
import { readFile } from "fs/promises";

type Results = {
    artworks: {
        name: string;
        extensions: string[] | undefined;
        link: string;
        image: string;
    }
};

function scrapeCarousel($: cheerio.CheerioAPI) {
    // result root - not really necessary though
    const results = $("div#search");
    // anchor element is the carousel container 
    // (visual artist works knowledgecard?)
    const carousel = $("[data-attrid=\"kc:/visual_art/visual_artist:works\"]", results);

    const items = $("img", carousel).map((_, img) => {
        const details = img.nextSibling;
        if (!details) {
            // log/raise for o11y
            throw new Error();
        }

        const name = $(details).children().first().text().trim();
        const maybeYearText = $(details).children().last().text();
        const hasExtensions = maybeYearText.trim().length !== 0;
        const extensions = hasExtensions 
            ? [ maybeYearText.trim() ] 
            : undefined;

        let image = $(img).attr("data-src") ?? $(img).attr("src");
        // images injected by a script
        // TODO: this will break gifs
        if (image?.startsWith("data:image/gif;")) {
            const imageId = $(img).attr("id");
            if (!imageId) {
                // log/throw for o11y - something's changed, what else has?
                throw new Error();
            }

            // ~~narrow down to specific script, using non-greedy quantifiers~~
            // just grab the two variables -_-
            // this WILL break if they change the script order
            // console.log(`var s='data:image/[a-z]+;base64,([\\\\A-Za-z0-9/+=]+)';var ii=\\['${imageId}'\\];`)
            // yes, the comma IS in the rfc
            const scriptData = $.html().match(new RegExp(`var s='(data:[a-z]+/[a-z]+;base64,[^']+)';var ii=\\['${imageId}'\\];`));
            // assume that `var ii=['<id>']` is stable enough
            if (scriptData && scriptData.length == 2) {
                image = scriptData[1]!;
                console.log(image.substring(image.length - 5, ));
                image = image.replace(/\\x3d/g, "=");
            } else {
                console.log(imageId);
            }
            // const imageData = scriptData.
        }


        const data = {
            name,
            extensions: extensions === undefined ? undefined : extensions, // what?
            // parentNode is carousel, by definition
            // also, the <a> is assumed to be relative
            link: (
                "https://www.google.com" 
                + $(img.parentNode!).attr("href")
            ),
            image,
        }

        // console.log(name, `"${maybeYearText}"`, maybeYearText.trim().length, extensions, data.extensions);

        return data;
    });


    return { artworks: items.toArray() };
}

async function main() {
    if (process.argv.length !== 3) {
        console.error(`USAGE: ${process.argv0} <file.html>`);
    }

    const html = await readFile(process.argv[2]!, { encoding: "utf-8" });
    const $ = cheerio.load(html);
    scrapeCarousel($).artworks.forEach(e => console.log(e.name, e.extensions))
    console.error(JSON.stringify(scrapeCarousel($), null, 2));
}


main();