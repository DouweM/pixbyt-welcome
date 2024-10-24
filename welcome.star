load("schema.star", "schema")
load("render.star", "render")
load("http.star", "http")
load("encoding/json.star", "json")
load("pixlib/input.star", "input")
load("./r.star", "r")

def people_by_room(people):
    rooms = {}
    for person in people:
        room = person.get("room", {}).get("display_name")

        if not room:
            continue

        if room not in rooms:
            rooms[room] = []

        rooms[room].append(person)

    return sorted(
        [
            (
                room,
                sorted(people, key=lambda person: person["person"]["display_name"])
            )
            for room, people in rooms.items()
        ],
        key=lambda r_c: -len(r_c[1]) # Rooms with more people first. TODO: Longer room names first?
    )

def main(config):
    SERVER_URL = config.get("server_url")
    HOME_ID = config.get("home_id")

    AVATARS_ONLY = config.bool("avatars_only")
    EXTRA_AVATAR_URLS = config.get("extra_avatar_urls", "").split(",")

    if not SERVER_URL:
        return render.Root(
            child=render.Box(
                child=render.WrappedText("Welcome Server URL not configured")
            )
        )

    def get_people():
        if HOME_ID:
            url = SERVER_URL + "/api/homes/" + HOME_ID + "/people"
        else:
            url = SERVER_URL + "/api/homes/people"

        response = http.get(url)

        if response.status_code != 200:
            fail("People not found", response)

        return response.json()

    people = get_people()
    if not people:
        return []

    if AVATARS_ONLY:
        image_urls = [
            person["person"]["avatar_url"]
            for person in people
            if person.get("person", {}).get("avatar_url")
        ]
        if EXTRA_AVATAR_URLS:
            image_urls.extend(EXTRA_AVATAR_URLS)

        if not image_urls:
            return []

        return render.Root(child=r.avatars(image_urls))

    rooms = people_by_room(people)
    return render.Root(child=r.rooms(rooms))

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Text(
                id = "server_url",
                name = "Welcome Server URL",
                desc = "If HTTPS, certificate must be valid. Example: 'https://welcome.example.com'",
                icon = "link"
            ),
            schema.Text(
                id = "home_id",
                name = "Home ID",
                desc = "The ID of the home to show. Example: 'main'",
                icon = "home"
            ),
            schema.Toggle(
                id = "avatars_only",
                name = "Show only avatars",
                desc = "Show a grid of avatars instead of rooms with names",
                icon = "face-smile",
                default = False,
            ),
            schema.Text(
                id = "extra_avatar_urls",
                name = "Extra avatar URLs",
                desc = "Comma-separated list of extra avatar URLs to show in the grid. Example: 'https://example.com/avatar1.png,https://example.com/avatar2.png'",
                icon = "key",
            ),
        ],
    )
