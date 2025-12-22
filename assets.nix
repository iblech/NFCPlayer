{ fetchFromYouTube, berryIcons }:

[
  # Baby Shark
  {
    src = fetchFromYouTube {
      url = "https://www.youtube.com/watch?v=XqZsoesa55w";
      hash = "sha256-3bLRH6YmxLNRLHR3ZHM+y5DAynAUr3lUrhh4dXosgro=";
    };
    # The hash can be obtained by first using a random placeholder
    # and then correcting it in view of the ensuing hash mismatch error
    # message.
    #
    # Instead of using fetchFromYouTube, you can also specify the path
    # to a directory containing the required files directly:
    # song.mp3, cover.jpeg and (optionally, for linking from the booklet) url.txt

    icon = berryIcons.black;
    # Instead of using berryIcons, you can also specify the path to
    # a JPEG file directly.

    tags = [ "aa:bb:cc:dd:ee:ff" ];
    # Add more IDs as needed.
  }

  # Put more assets here.
]
