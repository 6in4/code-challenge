import * as cheerio from "cheerio";
import { readFile } from "fs/promises";

type Results = {
    artworks: {
        name: string;
        extensions: string[] | undefined;
        link: string;
        image: string;
    }[];
};

export function scrapeCarousel($: cheerio.CheerioAPI): Results {
    // result root - not really necessary though
    const results = $("div#search");
    // anchor element is the carousel container 
    // (visual artist works knowledgecard?)
    const carousel = $("[data-attrid=\"kc:/visual_art/visual_artist:works\"]", results);

    const items = $("img", carousel).map((_, img) => {
        const details = $("div", $(img).parent())
        if (details.length === 0) {
            // work details missing! possible structure change?
            throw new Error("image details missing - structure changed?");
        }

        // name is first, year (if present) is last
        const name = $(details).children().first().text().trim();
        const maybeYearText = $(details).children().last().text();
        const hasExtensions = maybeYearText.trim().length !== 0;
        const extensions = hasExtensions 
            ? [ maybeYearText.trim() ] 
            : undefined;

        // when data-src is present, it will contain a URL to src
        // - src will be a blank gif
        let image = $(img).attr("data-src") ?? $(img).attr("src");
        // images injected by a script
        // this will not work if the image is truly a gif
        if (image?.startsWith("data:image/gif;")) {
            const imageId = $(img).attr("id");
            if (!imageId) {
                // log/throw for o11y - something's changed, what else has?
                throw new Error();
            }

            // this WILL break if they change the variable order in the script
            // assume that `var ii=['<id>']` is stable enough
            // also, yes, this is expensive relative to building a map in advance
            const scriptData = $.html().match(new RegExp(`var s='(data:[a-z]+/[a-z]+;base64,[^']+)';var ii=\\['${imageId}'\\];`));
            if (scriptData && scriptData.length == 2) {
                image = scriptData[1]!;
                image = image.replace(/\\x3d/g, "=");
            } else {
                console.error(imageId, );
                // increase the error rate - 
                // something needs to be fixed ASAP
                throw new Error("img.id is missing");
            }
        }

        // at this point, this should either be a jpeg or a cdn url - not a gif
        if (image?.startsWith("data:image/gif")) {
            throw new Error(`incorrect image type (name=${name})`);
        }

        const data = {
            name,
            extensions,
            // parentNode is carousel, by definition
            // also, the <a> is assumed to be relative
            link: (
                // to match expected-array.json (vs the file:// url)
                "https://www.google.com" 
                + $(img.parentNode!).attr("href")
            ),
            image: image!, // could also be string | undefined
        }

        return data;
    });


    return { artworks: items.toArray() };
}

async function main() {
    if (process.argv.length !== 3) {
        console.log(`USAGE: ${process.argv0} <file.html>`);
        console.log(`\tOR: npm start -- <file.html>`);
        process.exit(1);
    }

    const html = await readFile(process.argv[2]!, { encoding: "utf-8" });
    const $ = cheerio.load(html);
    console.log(JSON.stringify(scrapeCarousel($), null, 2));
}


main();