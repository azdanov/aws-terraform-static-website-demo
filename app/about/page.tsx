import Link from "next/link";
import { Inter } from 'next/font/google'

const inter = Inter({ subsets: ['latin'] })

export default function Home() {
  return (
    <main className={inter.className}>
      <section className="bg-white">
        <div className="layout relative flex min-h-screen flex-col items-center justify-center py-12 text-center">
          <h1 className="text-xl">About</h1>
          <p className="mt-2 text-sm text-gray-800">About page.</p>

          <nav>
            <ul className="flex flex-col mt-4 space-y-2">
              <li>
                <Link className="underline" href="/">
                  Home
                </Link>
              </li>
            </ul>
          </nav>

          <footer className="absolute bottom-2 text-gray-700">
            By{" "}
            <a className="underline" href="https://azdanov.dev/">
              Anton Ždanov
            </a>
          </footer>
        </div>
      </section>
    </main>
  );
}
