import {Controller} from "@hotwired/stimulus"

// Connects to data-controller="geolocate"
export default class extends Controller {
    static classes = ["supported"]

    static values = {
        url: String,
        active: Boolean
    }

    connect() {
        if (navigator.geolocation) {
            this.element.classList.add(this.supportedClass);
        }
    }

    redirect() {
        // the location filter is on, so clicking again turns it off
        if (this.activeValue) {
            Turbo.visit(this.urlValue);
            return;
        }

        // mobile devices throttle geolocation so cache it
        const cachedPin = this.getCachedPin();

        if (cachedPin) {
            this.doRedirect(cachedPin.lat, cachedPin.lon);
        } else if (navigator.geolocation) {
            this.element.setAttribute('aria-busy', 'true');
            navigator.geolocation.getCurrentPosition(
                this.handleSuccess.bind(this),
                this.handleError.bind(this)
            );
        } else {
            console.error("Geolocation is not supported by this browser.");
        }
    }

    handleSuccess(position) {
        this.element.removeAttribute('aria-busy');
        const lat = position.coords.latitude;
        const lon = position.coords.longitude;

        this.cachePin(lat, lon);
        this.doRedirect(lat, lon);
    }

    doRedirect(lat, lon) {
        let url = this.urlValue;
        const separator = url.includes('?') ? '&' : '?';
        url = `${url}${separator}pin=${lat},${lon}`;

        Turbo.visit(url);
    }

    cachePin(lat, lon) {
        const pinData = {
            lat: lat,
            lon: lon,
            expires: Date.now() + (60 * 1000) // 1 minute
        };
        localStorage.setItem('geolocatePin', JSON.stringify(pinData));
    }

    getCachedPin() {
        const pinJSON = localStorage.getItem('geolocatePin');
        if (!pinJSON) return null;
        
        const pinData = JSON.parse(pinJSON);

        if (pinData.expires > Date.now()) {
            return {
                lat: pinData.lat,
                lon: pinData.lon
            };
        } else {
            localStorage.removeItem('geolocatePin');
            return null;
        }
    }

    handleError(error) {
        this.element.removeAttribute('aria-busy');
        console.error("Error obtaining geolocation:", error.message);
    }
}
