from unittest.mock import patch

from django.contrib.auth import get_user_model
from django.test import TestCase
from django.urls import reverse

from app.models import (
    MediaTypes,
    Sources,
)


class TMDBRedirectViewTests(TestCase):
    """Test the TMDB link redirect views."""

    def setUp(self):
        """Create a user and log in."""
        self.credentials = {"username": "test", "password": "12345"}
        self.user = get_user_model().objects.create_user(**self.credentials)
        self.client.login(**self.credentials)

    @patch("app.providers.services.get_media_metadata")
    def test_movie_redirect(self, mock_get_metadata):
        """Test the movie redirect view."""
        mock_get_metadata.return_value = {
            "media_id": "238",
            "title": "Test Movie",
            "media_type": MediaTypes.MOVIE.value,
            "source": Sources.TMDB.value,
            "image": "http://example.com/image.jpg",
        }

        response = self.client.get(
            reverse("tmdb_movie_redirect", kwargs={"media_id": 238}),
        )

        self.assertEqual(response.status_code, 302)
        self.assertEqual(response.url, "/details/tmdb/movie/238/test-movie")

        mock_get_metadata.assert_called_once_with(
            MediaTypes.MOVIE.value,
            238,
            Sources.TMDB.value,
        )

    @patch("app.providers.services.get_media_metadata")
    def test_tv_redirect(self, mock_get_metadata):
        """Test the TV show redirect view."""
        mock_get_metadata.return_value = {
            "media_id": "1668",
            "title": "Test TV Show",
            "media_type": MediaTypes.TV.value,
            "source": Sources.TMDB.value,
            "image": "http://example.com/image.jpg",
        }

        response = self.client.get(
            reverse("tmdb_tv_redirect", kwargs={"media_id": 1668}),
        )

        self.assertEqual(response.status_code, 302)
        self.assertEqual(response.url, "/details/tmdb/tv/1668/test-tv-show")

        mock_get_metadata.assert_called_once_with(
            MediaTypes.TV.value,
            1668,
            Sources.TMDB.value,
        )

    @patch("app.providers.services.get_media_metadata")
    def test_season_redirect(self, mock_get_metadata):
        """Test the season redirect view."""
        mock_get_metadata.return_value = {
            "media_id": "1668",
            "title": "Test TV Show",
            "media_type": MediaTypes.TV.value,
            "source": Sources.TMDB.value,
            "image": "http://example.com/image.jpg",
        }

        response = self.client.get(
            reverse(
                "tmdb_season_redirect",
                kwargs={"media_id": 1668, "season_number": 1},
            ),
        )

        self.assertEqual(response.status_code, 302)
        self.assertEqual(
            response.url,
            "/details/tmdb/tv/1668/test-tv-show/season/1",
        )

        mock_get_metadata.assert_called_once_with(
            MediaTypes.TV.value,
            1668,
            Sources.TMDB.value,
        )

    @patch("app.providers.services.get_media_metadata")
    def test_episode_redirect(self, mock_get_metadata):
        """Test the episode redirect view."""
        mock_get_metadata.return_value = {
            "media_id": "1668",
            "title": "Test TV Show",
            "media_type": MediaTypes.TV.value,
            "source": Sources.TMDB.value,
            "image": "http://example.com/image.jpg",
        }

        response = self.client.get(
            reverse(
                "tmdb_episode_redirect",
                kwargs={
                    "media_id": 1668,
                    "season_number": 1,
                    "episode_number": 3,
                },
            ),
        )

        self.assertEqual(response.status_code, 302)
        self.assertEqual(
            response.url,
            "/details/tmdb/tv/1668/test-tv-show/season/1#episode-3",
        )

        mock_get_metadata.assert_called_once_with(
            MediaTypes.TV.value,
            1668,
            Sources.TMDB.value,
        )
