# ADC 2026 Wavelets Script

## Slide 1

Hello, and welcome to my talk which will hopefully introduce you to wavelets and how you can use them to build practical, and good sounding audio effects.

## Slide 2

Today, we will discuss firstly who I am. Then I will go over what wavelets are, when and where you would use them, and lastly I'll give you some practical examples

## Slide 4

My name is D'Angelo, I have a Masters in Computer Science and Electronics from this city, the University of Bristol, and since graduating I've been working in the pro audio industry.

## Slide 6

So what is a wavelet? On the left, we have the sine wave we know and love, and on the right is a wavelet, as the name implies the wavelet is like a shortened wave. They aren't new, they've been around since 1909, where they are mainly used in image processing, radar techology, and biomedical applications.

## Slide 7

Specifically, a wavelet is defined as a short burst of oscillation. They are localised in both time and frequency, which is what makes them so useful. Moreover, they follow a zero-mean condition, meaning they have finite energy and integrate to 0, making the transform invertible. And to use them in analysis you simply shift and scale them across the signal, which we will go into more later on.

## Slide 8

The wavelet we saw earlier isn't the only wavelet. There are many different families or "mother wavelets" you can choose to decompose a signal, There are many different properties you can select a wavelet for: Symmetry, Smoothness, Orthogonality, support length (which tells you how long a wavelet is non-0 and how well it localises), and vanishing moments (which refers to a wavelet's ability to "ignore" a polynomial up to degree n-1). On the right we have some of the more popular ones, Haar (which was the first wavelet to be defined) Daubechies, Bi-Orthogonal (used in the JPEG 2000 codec), and the very creatively named mexican hat wavelet.

## Slide 9

If you read the title as listed in the programme, you may have noticed I made a bold claim. I said that wavelets can stop the transient smearing that the fourier transform causes. Well I may have lied a tiny bit. in a true fourier transform, with infinite frequencies across all of time, then yes you don't actually smear transients. But we don't get the luxury of all of time and infinitesimally small frequency bins in digital audio. Instead, when we want to split up a signal into frequencies we have to use the short time fourier transform or in the digital realm, the discrete fourier transform, splitting the signal up into nice, even frequency bins as we see on the left here (not to scale) that end up messing up our snare hits and guitar picks when we try and modify our signal in the frequency domain. Wavelet transforms, as we see on the right (again not to scale), don't have evenly spaced frequency bins. Instead they take a "multi-resolution" approach, giving you less frequency resolution, but higher time resolution in the higher frequencies, and vice-versa in the lower ones.

## Slide 10

So to be clear, wavelet transforms aren't perfect. Both the Fourier and Wavelet transforms are subject to Gabor's limit, Which is like Heisenberg's uncertainty principal, it says you can't perfectly localise a signal in both frequency and time. The STFT's evenly spaced frequency bins may be good for radio communications, but in the audio world, it means that short lived transients appear to last for the entire duration of a frequency bin, and also you end up processing frequencies that may not need it. With the wavelet's multi resolution approach, you allocate time and frequency resolution where its most useful. Transients that are short but have lots of high frequency content get more accurately captured, while longer lived, bass frequencies don't get any unnecessary work by giving them too much time resolution. The way the wavelet transform splits up frequency and time is also a lot more similar to how human hearing works. Wavelet's "frequency bands" are logarithmically split up, like how different notes are logarithmically increasing in frequency.

## Slide 11

I've spoken a lot about the wavelet transforms, but how do you actually do them. Here you see the Continuous Wavelet Transform, I won't go into it too much, since it is a lot less useful in digital audio, but here we see the equation for the continuous wavelet transform, with all the components we talked about, the mother wavelet, and the scaling and shifting along the signal. This second equation may show how it works a bit better, when you do a wavelet transform you essentially perform a convolution between it and the signal at different scales which, like the STFT, produces a 2d array of coefficients.

## Slide 12

The DWT is performed completely differently to the CWT. It is essentially performing a high-pass filter and low-pass filter operation on a signal, and then decimating both outputs to produce detail and approximation coefficients. Then you can do the same on the approximation coefficients again and again ad nauseum. Here there is no direct link to the mother wavelet, instead it is used to define the filter coefficients. This transform, like the STFT, is perfectly reconstructable, you can go from signal to coefficients and back without losing any data. It also has no redundant data, which is why it gets used a lot for compression algorithms. Because of the decimation, it means this transform runs in O(n) time complexity too. There are undecimated variants of this transform, which does introduce redundant coefficients and increases time complexity, but it is useful when you are modifying coefficients directly to avoid any artefacting due to aliasing or phase issues,

## Slide 14

So when should we use wavelets then, they won't replace the fourier transform by any means. But, if you have a signal with a lot of transients, you want to do some form of non-uniform band processing, or you want low-latency multiband analysis, they may be worth another look

## Slide 15

But, they aren't perfect. If you have a purely tonal, stationary signal, the fourier transform will almost definitely serve your needs better. Also if you need to precisely target a frequency then, again, Fourier's your guy. On top of that, most standard, orthogonal wavelets don't exhibit linear phase response, and you need to do a lot of experimentation with parameters, selecting a mother wavelet, on top of everything else, in order to get wavelets to work best for your application. Lastly, as I'm sure I've made painfully clear, wavelets aren't the easiest to explain. They're so much more complex than what this talk has gotten into, they really aren't as intuitive as the FFT and the libraries and tooling out there for them aren't that mature for audio.

## Slide 16

Let's get to the fun part, the examples. I've spent this whole talk explaining wht wavelets can do, but I haven't shown you.

## Slide 17

Firstly, let's show you where wavelets shine. Signal analysis. Here we're using wavelets to find transients in a drum track, then using a standard gain computer to give them a bit more punch. You've probably seen something similar to the block diagram on the right a bunch of times, but now this time it's got wavelets. heres the original track

And here's the shaped one

## Slide 18

And just to show it is actually detecting the transients, here's a small snip of the audio waveform and where our detector found the transients, see how it even picked up the really quiet ghost hits.

## Slide 19

What about modifying the coefficients directly? Well here we do just that. In this system we used an undecimated wavelet transform for the reasons mentioned before. Our sound changes as you hopefully heard, but the overall level didn't. This is using the same detector as previous, but a different modification strategy. You may be looking at the two spectrograms on the right and thinking "D'Angelo, they both look exactly the same" But what if i were to show you the difference between the two. You see? with the DWT

## SLide 20

Now what about the CWT, has it got any use? Well infact yes it does.

For this pitch shifter, we implement is as a constant-Q filter bank, which is mathematically identical to the CWT. We essentially form a pitch-shifter where resolution scales with frequency, meaning now our semitone shift is a bin shift, so there's no need to resample anything. Now this does use the CWT, not the DWT, so there are some major caveats. The main one being time. Running this took 5 seconds of processing for each second of audio. Now this was an octave prototype, and there is academic research showing this can be done in real time, but again the tools to do this are not that mature.

## Slide 21

Thanks for listening, my slides, octave code, references, and also an approximate script will be made available on my github, and if you have any questions then please come and find me!
