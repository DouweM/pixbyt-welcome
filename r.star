load("render.star", "render")
load("http.star", "http")
load("cache.star", "cache")
load("pixlib/const.star", "const")

r.AVATAR_CONFIGURATIONS = {
    #   column_align        row_align           per_row size
    1: ("center",           "center",           1,      const.HEIGHT),
    2: ("center",           "space_between",    2,      const.HEIGHT - 1),
    3: ("center",           "space_around",     3,      (const.WIDTH - 2) // 3),
    4: ("space_between",    "space_evenly",     2,      const.HEIGHT // 2 - 1),
    5: ("space_between",    "space_evenly",     3,      const.HEIGHT // 2 - 1),
    6: ("space_between",    "space_evenly",     3,      const.HEIGHT // 2 - 1),
    7: ("space_between",    "space_evenly",     4,      const.HEIGHT // 2 - 1),
    8: ("space_between",    "space_between",    4,      const.HEIGHT // 2 - 1),
}

def r.avatars(image_urls):
    column_align, row_align, per_row, size = r.AVATAR_CONFIGURATIONS.get(len(image_urls), r.AVATAR_CONFIGURATIONS[8])

    row = []
    rows = [row]
    for url in image_urls:
        if len(row) == per_row:
            if len(rows) * size + size > const.HEIGHT:
                break

            row = []
            rows.append(row)

        row.append(url)

    return render.Column(
            expanded=True,
            main_align=column_align,
            children=[
                render.Row(
                    expanded=True,
                    main_align=row_align,
                    cross_align=column_align,
                    children=[r.avatar(url, size) for url in row]
                )
                for row in rows
            ]
        )

def r.rooms(rooms):
    return render.Column(
        expanded=True,
        children=[
            r.room(room, clients, i, len(rooms))
            for i, (room, clients) in enumerate(rooms)
        ]
    )

def r.room(room, clients, index, room_count):
    if room_count == 1:
        return render.Column(
            children=[
                r.room_name(room, pad=(0,0,0,1)),
                r.clients(
                    clients,
                    scroll_direction="vertical",
                    height=const.HEIGHT-8-1,
                    pad_client=(0,0,0,1),
                    image_size=(10 if len(clients) <= 2 else 8)
                )
            ]
        )

    if room_count == 2 or (room_count == 3 and index == 0):
        return render.Column(
            children=[
                r.room_name(room),
                r.clients(
                    clients,
                    scroll_direction="horizontal",
                    width=const.WIDTH,
                    pad_client=(0,0,4,0)
                )
            ]
        )

    return render.Row(
        children=[
            r.room_name(room, pad=(0,0,1,0)),
            r.clients(
                clients,
                scroll_direction="horizontal",
                width=const.WIDTH - len(room) * 5 + 1, # Not exact
                pad_client=(0,0,4,0)
            )
        ]
    )

def r.clients(clients, pad_client=(0,0,0,0), image_size=8, scroll_direction="horizontal", **kwargs):
    return render.Marquee(
        scroll_direction=scroll_direction,
        child=(render.Row if scroll_direction == "horizontal" else render.Column)(
            children=[
                render.Padding(
                    pad=((0,0,0,0) if i == len(clients) - 1 else pad_client),
                    child=r.client(client, image_size)
                )
                for i, client in enumerate(clients)
            ]
        ),
        **kwargs,
    )

def r.client(client, image_size, subtitle=None):
    text = render.Text(client["person"]["display_name"])

    expanded = False
    if subtitle:
        expanded = True
        text = render.Column(
            children=[
                text,
                render.Text(subtitle, color="#bbbbbb")
            ]
        )

    avatar_url = client["person"].get("avatar_url")
    if avatar_url:
        avatar = r.avatar(avatar_url, image_size, pad=(0,0,2,0))
        children = [avatar, text]
    else:
        children = [text]

    return render.Row(
        cross_align="center",
        expanded=expanded,
        children=children
    )

def r.room_name(room, pad=(0,0,0,0)):
    return render.Padding(
        pad=pad,
        child=render.Text(room, color="#bbbbbb")
    )

def r.avatar(url, size, pad=(0,0,0,0)):
    return render.Padding(
        pad=pad,
        child=render.Image(src=r._image_data(url), height=size, width=size)
    )

def r._image_data(url):
    cached = cache.get(url)
    if cached:
        return cached

    response = http.get(url)

    if response.status_code != 200:
        fail("Image not found", url)

    data = response.body()
    cache.set(url, data, ttl_seconds=60 * 60 * 24)

    return data
