import { it, expect, vi } from "vitest";

// to workaround process.exit(1)
vi.hoisted(() => { process.argv = ["", "", "/dev/null"]; });

import { readFileSync } from "fs";
import { resolve } from "path";
import * as cheerio from "cheerio";
import { scrapeCarousel } from "./main";

const filesDir = resolve(__dirname, "../../files");

function scrape(filename: string) {
    const html = readFileSync(resolve(filesDir, filename), "utf-8");
    return scrapeCarousel(cheerio.load(html));
}

it("van gogh paintings matches expected", () => {
    const result = scrape("van-gogh-paintings.html");
    const expected = JSON.parse(readFileSync(resolve(filesDir, "expected-array.json"), "utf-8"));
    expect(result).toEqual(expected);
});
