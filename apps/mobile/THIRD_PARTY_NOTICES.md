# Mobile native dependency notices

The Android identity adapter uses official signalapp/libsignal 0.104.0:

- org.signal:libsignal-android:0.104.0
- org.signal:libsignal-client:0.104.0
- Upstream: https://github.com/signalapp/libsignal/tree/v0.104.0
- License: GNU Affero General Public License, version 3. The upstream license is retained in licenses/libsignal-0.104.0-LICENSE.txt.

The new native identity adapter and its tests carry SPDX-License-Identifier: AGPL-3.0-only. Existing MIT source permissions and third-party attributions remain intact. Distribution of a linked mobile application needs the applicable AGPL source, license and notice obligations fulfilled; this file does not establish that a binary release is ready. No binary release has been performed. Native artifact verification, complete dependency notices/SBOM and corresponding-source packaging remain release work.

Java desugaring uses com.android.tools:desugar_jdk_libs:2.1.5 (https://github.com/google/desugar_jdk_libs). Unit tests use JUnit 4.13.2 (https://github.com/junit-team/junit4). Preserve their upstream dependency license notices in release packaging.

Android instrumentation tests use androidx.test.ext:junit:1.2.1 and androidx.test:runner:1.6.2 (https://github.com/android/android-test). These are test-only dependencies; their notices belong in the corresponding test/source dependency inventory.
